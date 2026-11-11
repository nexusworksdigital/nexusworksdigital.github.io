package com.nexusworksdigital.nexustuner;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import androidx.core.content.FileProvider;

import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.MessageDigest;

/**
 * Ponte entre o app (JavaScript) e o Android: versão instalada e atualização automática.
 * No JavaScript: window.NexusAndroid.versionCode(), .versionName(), .canSelfUpdate(), .startUpdate(url, sha256)
 * Eventos voltam por window.nexusUpdateEvent(tipo, valor): progress · installing · permission · error
 */
public class NexusBridge {

    static final int REQ_INSTALL = 77;
    private static final String ALLOWED = "https://github.com/nexusworksdigital/";

    private final Activity act;
    private final WebView web;
    private File pendingApk;
    private volatile boolean busy = false;

    NexusBridge(Activity act, WebView web) {
        this.act = act;
        this.web = web;
    }

    private PackageInfo info() {
        try {
            return act.getPackageManager().getPackageInfo(act.getPackageName(), 0);
        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    @JavascriptInterface
    public int versionCode() {
        PackageInfo i = info();
        if (i == null) return 0;
        return Build.VERSION.SDK_INT >= 28 ? (int) i.getLongVersionCode() : i.versionCode;
    }

    @JavascriptInterface
    public String versionName() {
        PackageInfo i = info();
        return i == null || i.versionName == null ? "" : i.versionName;
    }

    @JavascriptInterface
    public boolean canSelfUpdate() {
        return BuildConfig.SELF_UPDATE;
    }

    @JavascriptInterface
    public void startUpdate(final String url, final String sha256) {
        if (!BuildConfig.SELF_UPDATE) return;
        if (url == null || !url.startsWith(ALLOWED)) {
            emit("error", "download");
            return;
        }
        if (busy) return;
        busy = true;
        new Thread(() -> {
            try {
                File apk = download(url, sha256);
                if (apk == null) return;            // erro já avisado
                act.runOnUiThread(() -> install(apk));
            } finally {
                busy = false;
            }
        }, "nexus-update").start();
    }

    private File download(String url, String sha256) {
        File dir = new File(act.getCacheDir(), "updates");
        if (!dir.exists() && !dir.mkdirs()) {
            emit("error", "download");
            return null;
        }
        File[] old = dir.listFiles();
        if (old != null) for (File f : old) //noinspection ResultOfMethodCallIgnored
            f.delete();
        File out = new File(dir, "NexusTuner.apk");
        HttpURLConnection c = null;
        try {
            // o GitHub redireciona o download para outro endereço https
            String next = url;
            for (int i = 0; i < 6; i++) {
                c = (HttpURLConnection) new URL(next).openConnection();
                c.setInstanceFollowRedirects(false);
                c.setConnectTimeout(15000);
                c.setReadTimeout(30000);
                int code = c.getResponseCode();
                if (code >= 300 && code < 400) {
                    String loc = c.getHeaderField("Location");
                    c.disconnect();
                    if (loc == null || !loc.startsWith("https://")) throw new IOException("redirect");
                    next = loc;
                    continue;
                }
                if (code != 200) throw new IOException("HTTP " + code);
                break;
            }
            long total = c.getContentLengthLong();
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (InputStream in = c.getInputStream(); FileOutputStream fo = new FileOutputStream(out)) {
                byte[] b = new byte[64 * 1024];
                long done = 0;
                int n, last = -1;
                while ((n = in.read(b)) > 0) {
                    fo.write(b, 0, n);
                    md.update(b, 0, n);
                    done += n;
                    if (total > 0) {
                        int p = (int) (done * 100 / total);
                        if (p != last) {
                            last = p;
                            emit("progress", String.valueOf(p));
                        }
                    }
                }
            }
            StringBuilder hex = new StringBuilder();
            for (byte x : md.digest()) hex.append(String.format("%02x", x));
            if (sha256 != null && !sha256.isEmpty() && !hex.toString().equalsIgnoreCase(sha256.trim())) {
                //noinspection ResultOfMethodCallIgnored
                out.delete();
                emit("error", "checksum");
                return null;
            }
            return out;
        } catch (Exception e) {
            emit("error", "download");
            return null;
        } finally {
            if (c != null) c.disconnect();
        }
    }

    /** Abre o instalador do Android; pede a permissão de "apps desconhecidos" se faltar. */
    void install(File apk) {
        if (Build.VERSION.SDK_INT >= 26 && !act.getPackageManager().canRequestPackageInstalls()) {
            pendingApk = apk;
            emit("permission", "");
            Intent i = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:" + act.getPackageName()));
            try {
                act.startActivityForResult(i, REQ_INSTALL);
            } catch (Exception e) {
                emit("error", "permission");
            }
            return;
        }
        try {
            Uri uri = FileProvider.getUriForFile(act, act.getPackageName() + ".files", apk);
            Intent i = new Intent(Intent.ACTION_VIEW);
            i.setDataAndType(uri, "application/vnd.android.package-archive");
            i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
            act.startActivity(i);
            emit("installing", "");
        } catch (Exception e) {
            emit("error", "download");
        }
    }

    /** Volta da tela de permissão. */
    void onInstallPermissionResult() {
        if (pendingApk == null) return;
        File apk = pendingApk;
        pendingApk = null;
        if (Build.VERSION.SDK_INT < 26 || act.getPackageManager().canRequestPackageInstalls()) install(apk);
        else emit("error", "permission");
    }

    private void emit(String type, String value) {
        final String js = "window.nexusUpdateEvent && window.nexusUpdateEvent("
                + JSONObject.quote(type) + "," + JSONObject.quote(value == null ? "" : value) + ")";
        act.runOnUiThread(() -> web.evaluateJavascript(js, null));
    }
}
