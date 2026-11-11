import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/updates.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';
import '../widgets/nexus_logo.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Central de notificações (sino).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: NX.bg,
        title: Text('Notificações', style: NX.sora(18)),
        actions: [
          ListenableBuilder(
            listenable: updates,
            builder: (_, __) => TextButton(
              onPressed: updates.unread == 0 ? null : updates.markAllRead,
              child: const Text('Marcar todas como lidas'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: NX.accent,
        onRefresh: updates.check,
        child: ListenableBuilder(
          listenable: updates,
          builder: (context, _) {
            final list = updates.notifications;
            if (list.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 120),
                Icon(Icons.notifications_none, size: 64, color: NX.dim),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    updates.offline ? 'Sem conexão. Puxe para atualizar.' : 'Nenhuma notificação por enquanto.',
                    style: NX.inter(14, c: NX.metal),
                  ),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _NotifTile(n: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NxNotification n;
  const _NotifTile({required this.n});

  @override
  Widget build(BuildContext context) {
    final read = updates.isRead(n);
    final (icon, color) = switch (n.type) {
      'update' => (Icons.system_update, NX.accent),
      'notice' => (Icons.campaign_outlined, NX.warn),
      _ => (Icons.auto_awesome, NX.silver),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        updates.markRead(n);
        if (n.type == 'update') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdateScreen()));
        } else if (n.link != null) {
          updates.openLink(n.link!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: NX.cardDeco(active: n.type == 'update' && !read),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(n.title,
                      style: NX.inter(14.5, w: read ? FontWeight.w500 : FontWeight.w700, c: NX.white)),
                ),
                if (!read)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: NX.accent),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(n.body, style: NX.inter(12.5, c: NX.silver)),
              const SizedBox(height: 6),
              Row(children: [
                Text(_date(n.date), style: NX.inter(11, c: NX.dim)),
                const Spacer(),
                if (n.type == 'update')
                  Text('Ver e atualizar ›', style: NX.inter(12, w: FontWeight.w700, c: NX.accent))
                else if (n.link != null)
                  Text('Abrir ›', style: NX.inter(12, w: FontWeight.w600, c: NX.accent)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Seção de atualizações: novidades + atualizar com um toque.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: NX.bg, title: Text('Atualizações', style: NX.sora(18))),
      body: ListenableBuilder(
        listenable: updates,
        builder: (context, _) {
          final r = updates.latest;
          final has = updates.hasUpdate;
          final busy = updates.phase == UpdatePhase.downloading || updates.phase == UpdatePhase.installing;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Center(child: NexusMark(size: 70)),
              const SizedBox(height: 12),
              Center(
                child: Text(has ? 'Nova versão disponível!' : 'Você está na versão mais recente',
                    style: NX.sora(20, w: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Instalada: ${updates.currentName.isEmpty ? '—' : updates.currentName}'
                  '${r == null ? '' : '   ·   Disponível: ${r.versionName}'}',
                  style: NX.inter(13, c: NX.metal),
                ),
              ),
              const SizedBox(height: 20),
              if (r != null)
                NxCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SectionLabel('Novidades da versão ${r.versionName}',
                        trailing: Text(_date(r.date), style: NX.inter(11.5, c: NX.metal))),
                    for (final note in r.notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_circle, size: 16, color: NX.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(note, style: NX.inter(13.5, c: NX.white))),
                        ]),
                      ),
                  ]),
                ),
              const SizedBox(height: 18),
              if (busy) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: updates.phase == UpdatePhase.installing ? null : updates.progress,
                    minHeight: 10,
                    color: NX.accent,
                    backgroundColor: NX.border,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    updates.phase == UpdatePhase.installing
                        ? 'Abrindo o instalador… toque em "Atualizar" na tela do Android.'
                        : 'Baixando… ${(updates.progress * 100).round()}%',
                    style: NX.inter(13, c: NX.silver),
                  ),
                ),
              ] else if (kIsWeb)
                Text('Você está usando a versão de navegador: ela é atualizada automaticamente '
                    'sempre que você abre o app.',
                    textAlign: TextAlign.center, style: NX.inter(13.5, c: NX.silver))
              else if (has)
                PrimaryButton(
                  label: 'Atualizar agora',
                  icon: Icons.system_update,
                  height: 52,
                  onPressed: updates.startUpdate,
                )
              else
                OutlineBtn(
                  label: updates.phase == UpdatePhase.checking ? 'Verificando…' : 'Verificar novamente',
                  icon: Icons.refresh,
                  height: 48,
                  onPressed: updates.phase == UpdatePhase.checking ? null : updates.check,
                ),
              if (updates.phase == UpdatePhase.error && updates.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: NX.cardDeco(borderColor: NX.bad.withOpacity(0.6)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(updates.error!, style: NX.inter(13)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlineBtn(label: 'Tentar de novo', icon: Icons.refresh, onPressed: updates.startUpdate),
                      OutlineBtn(label: 'Baixar pelo navegador', icon: Icons.open_in_new, onPressed: updates.openInBrowser),
                    ]),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                updates.lastCheck == null
                    ? ''
                    : 'Última verificação: ${_date(updates.lastCheck!)} às '
                        '${updates.lastCheck!.hour.toString().padLeft(2, '0')}:${updates.lastCheck!.minute.toString().padLeft(2, '0')}'
                        '${updates.offline ? ' (sem conexão)' : ''}',
                textAlign: TextAlign.center,
                style: NX.inter(11.5, c: NX.dim),
              ),
              const SizedBox(height: 6),
              Text(
                'O app verifica novidades sempre que é aberto. As atualizações vêm do site oficial '
                'nexusworksdigital.github.io e mantêm todos os seus kits, presets e medições.',
                textAlign: TextAlign.center,
                style: NX.inter(11.5, c: NX.dim),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Sino com contador para o cabeçalho.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        final n = updates.unread;
        return IconButton(
          tooltip: 'Notificações',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          icon: Stack(clipBehavior: Clip.none, children: [
            Icon(n > 0 ? Icons.notifications_active_outlined : Icons.notifications_none,
                color: NX.white, size: 26),
            if (n > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: NX.accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: NX.glowShadow(blur: 8),
                  ),
                  child: Text('$n',
                      textAlign: TextAlign.center,
                      style: NX.inter(11, w: FontWeight.w700, c: NX.white)),
                ),
              ),
          ]),
        );
      },
    );
  }
}
