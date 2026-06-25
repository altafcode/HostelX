mport os
import re

path = 'c:\\Users\\altaf\\StudioProjects\\hostelX\\lib\\features\\owner\\tabs\\owner_dashboard_tab.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if missing
if 'import \\'../widgets/request_card.dart\\';' not in content:
    content = content.replace(
        'import \\'../widgets/activity_item.dart\\';',
        'import \\'../widgets/activity_item.dart\\';\nimport \\'../widgets/request_card.dart\\';'
    )

# Replace ActivityItem with RequestCard in pending bookings
replacement = '''              ...pendingBookings.take(3).map(
                    (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RequestCard(booking: b),
                ),
              ),'''

content = re.sub(
    r'              \.\.\.pendingBookings\.take\(3\)\.map\(\s*\(b\) => Padding\(\s*padding: const EdgeInsets\.only\(bottom: 10\),\s*child: ActivityItem\(\s*booking: b,\s*onTap: \(\) => Navigator\.push\(\s*context,\s*MaterialPageRoute\(builder: \(_\) => const OwnerBookingRequestsScreen\(\)\),\s*\),\s*\),\s*\),\s*\),',
    replacement,
    content
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Changed ActivityItem back to RequestCard")
