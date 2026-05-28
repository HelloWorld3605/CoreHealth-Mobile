import 'package:flutter/material.dart';
import '../app_controller.dart';
import '../theme.dart';
import '../widgets/visuals.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final settings = controller.settings;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Cài đặt hệ thống'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Account Group
          _buildGroupHeader('Tài khoản'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Chỉnh sửa hồ sơ',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                const Divider(),
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Bảo mật tài khoản',
                  onTap: () => _showWipToast(context, 'Bảo mật tài khoản'),
                ),
              ],
            ),
          ),
          // Notifications Group
          const SizedBox(height: 20),
          _buildGroupHeader('Thông báo nhắc nhở'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.local_drink_outlined,
                  title: 'Nhắc nhở uống nước',
                  subtitle: 'Nhắc uống nước đều đặn mỗi 2 tiếng.',
                  value: settings.waterReminderEnabled,
                  onChanged: (val) => controller.updateSettings(
                    settings.copyWith(waterReminderEnabled: val),
                  ),
                  color: AppPalette.blue,
                ),
                const Divider(),
                _buildSwitchTile(
                  icon: Icons.fitness_center_rounded,
                  title: 'Lịch tập luyện trong ngày',
                  subtitle: 'Nhắc nhở chuẩn bị tập trước 30 phút.',
                  value: settings.workoutReminderEnabled,
                  onChanged: (val) => controller.updateSettings(
                    settings.copyWith(workoutReminderEnabled: val),
                  ),
                  color: AppPalette.orange,
                ),
                const Divider(),
                _buildSwitchTile(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Cập nhật cân nặng tuần',
                  subtitle: 'Nhắc đo cân nặng vào sáng thứ hai.',
                  value: settings.weeklyWeightReminderEnabled,
                  onChanged: (val) => controller.updateSettings(
                    settings.copyWith(weeklyWeightReminderEnabled: val),
                  ),
                  color: AppPalette.emeraldDeep,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // General Group
          _buildGroupHeader('Chung'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Ngôn ngữ',
                  trailing: Text(
                    settings.language,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppPalette.mutedText),
                  ),
                  onTap: () => _showLanguageSelector(context, controller),
                ),
                const Divider(),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Chính sách bảo mật',
                  onTap: () => _showWipToast(context, 'Chính sách bảo mật'),
                ),
                const Divider(),
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Trung tâm trợ giúp',
                  onTap: () => _showWipToast(context, 'Trung tâm trợ giúp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppPalette.mutedText,
            fontSize: 13),
      ),
    );
  }

  static Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppPalette.text),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded, color: AppPalette.subtleText),
      onTap: onTap,
    );
  }

  static Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: color),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      value: value,
      activeThumbColor: AppPalette.emerald,
      onChanged: onChanged,
    );
  }

  static void _showLanguageSelector(
    BuildContext context,
    AppController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Chọn ngôn ngữ',
              style: TextStyle(fontWeight: FontWeight.w800)),
          children: ['Tiếng Việt', 'English']
              .map(
                (lang) => SimpleDialogOption(
                  onPressed: () {
                    controller.updateSettings(
                      controller.settings.copyWith(language: lang),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(lang,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              )
              .toList(),
        );
      },
    );
  }

  static void _showWipToast(BuildContext context, String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Tính năng "$page" sẽ được tích hợp trong phiên bản tới.')),
    );
  }
}
