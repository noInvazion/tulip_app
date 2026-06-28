import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? badge;
  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge,
  });
}

class Sidebar extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: TulipColors.sidebar,
      child: Column(
        children: [
          // Brand
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TulipColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Image.asset('assets/tulip_logo.jpg', width: 32, height: 32),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TULIP', style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: TulipColors.text, letterSpacing: -0.5)),
                  Text('MAMMOGRAPHY TRIAGE', style: GoogleFonts.dmSans(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: TulipColors.textT, letterSpacing: 0.8)),
                ]),
              ],
            ),
          ),
          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NavSectionLabel('Workspace'),
                  ...items.sublist(0, 4).asMap().entries.map((e) =>
                    _SidebarNavItem(
                      item: e.value, index: e.key,
                      isActive: selectedIndex == e.key,
                      onTap: () => onSelect(e.key),
                    )),
                  _NavSectionLabel('System'),
                  ...items.sublist(4).asMap().entries.map((e) =>
                    _SidebarNavItem(
                      item: e.value, index: e.key + 4,
                      isActive: selectedIndex == e.key + 4,
                      onTap: () => onSelect(e.key + 4),
                    )),
                ],
              ),
            ),
          ),
          // User footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TulipColors.border, width: 0.5)),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TulipColors.p200, TulipColors.p400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('AN', style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. A. Nwosu', style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500, color: TulipColors.text)),
                Text('Radiologist', style: GoogleFonts.dmSans(
                    fontSize: 10, color: TulipColors.textT)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  final String label;
  const _NavSectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
    child: Text(label.toUpperCase(), style: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: TulipColors.textT, letterSpacing: 0.8)),
  );
}

class _SidebarNavItem extends StatelessWidget {
  final NavItem item;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  const _SidebarNavItem({
    required this.item,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? TulipColors.p50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(isActive ? item.activeIcon : item.icon, size: 16,
            color: isActive ? TulipColors.p600 : TulipColors.gray400),
          const SizedBox(width: 10),
          Text(item.label, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: isActive ? TulipColors.p800 : TulipColors.textS)),
          if (item.badge != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: TulipColors.red400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(item.badge!, style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}
