import re

path = 'c:\\Users\\altaf\\StudioProjects\\hostelX\\lib\\features\\owner\\providers\\owner_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacement1 = '''        List<Tenant> loadedTenants = [];
        for (var b in confirmedBookings) {
          try {
            UserEntity? user;
            if (b.userId.isNotEmpty) {
              final userDoc = await _db.collection('users').doc(b.userId).get();
              if (userDoc.exists && userDoc.data() != null) {
                user = UserEntity.fromMap(b.userId, userDoc.data()!);
              }
            }
            loadedTenants.add(Tenant.fromBooking(b, user));
          } catch (e) {
            loadedTenants.add(Tenant.fromBooking(b));
          }
        }
        tenants = loadedTenants;'''

content = re.sub(
    r'        List<Tenant> loadedTenants = \[\];\s*for \(var b in confirmedBookings\) \{\s*final userDoc = await _db\.collection\(\'users\'\)\.doc\(b\.userId\)\.get\(\);\s*UserEntity\? user;\s*if \(userDoc\.exists\) \{\s*user = UserEntity\.fromMap\(b\.userId, userDoc\.data\(\)!\);\s*\}\s*loadedTenants\.add\(Tenant\.fromBooking\(b, user\)\);\s*\}\s*tenants = loadedTenants;',
    replacement1,
    content
)

replacement2 = '''      List<Tenant> newTenants = [];
      for (var b in confirmedBookings) {
        try {
          UserEntity? user;
          if (b.userId.isNotEmpty) {
            final userDoc = await _db.collection('users').doc(b.userId).get();
            if (userDoc.exists && userDoc.data() != null) {
              user = UserEntity.fromMap(b.userId, userDoc.data()!);
            }
          }
          newTenants.add(Tenant.fromBooking(b, user));
        } catch (e) {
          newTenants.add(Tenant.fromBooking(b));
        }
      }
      tenants = newTenants;'''

content = re.sub(
    r'      List<Tenant> newTenants = \[\];\s*for \(var b in confirmedBookings\) \{\s*final userDoc = await _db\.collection\(\'users\'\)\.doc\(b\.userId\)\.get\(\);\s*UserEntity\? user;\s*if \(userDoc\.exists\) \{\s*user = UserEntity\.fromMap\(b\.userId, userDoc\.data\(\)!\);\s*\}\s*newTenants\.add\(Tenant\.fromBooking\(b, user\)\);\s*\}\s*tenants = newTenants;',
    replacement2,
    content
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("owner_provider.dart updated safely")
