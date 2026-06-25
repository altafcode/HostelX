class AppStrings {
  AppStrings._();

  // General
  static const String appName        = 'HostelX';
  static const String appVersion     = 'v1.0.0';
  static const String tagline        = 'Find Your Home Away From Home';
  static const String seeAll         = 'See All';
  static const String noResults      = 'No results found';
  static const String loading        = 'Loading...';

  // Auth
  static const String login          = 'Login';
  static const String register       = 'Register';
  static const String logout         = 'Logout';
  static const String email          = 'Email Address';
  static const String password       = 'Password';
  static const String fullName       = 'Full Name';
  static const String phone          = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String haveAccount    = 'Already have an account?';
  static const String noAccount      = "Don't have an account?";
  static const String enterEmail     = 'Enter your email';
  static const String enterPassword  = 'Enter your password';
  static const String enterName      = 'Enter your full name';
  static const String enterPhone     = 'Enter your phone number';
  static const String createPassword = 'Create a password';
  static const String enterCreds     = 'Enter Your Credentials';
  static const String createAccount  = 'Create your account';
  static const String welcomeBack    = 'Welcome Back!';
  static const String selectRole     = 'Select your role to continue';

  // Roles
  static const String student        = 'Tenant';
  static const String hostelOwner    = 'Hostel Owner';
  static const String admin          = 'Admin';
  static const String findBook       = 'Find and book hostels';
  static const String manageHostels  = 'Manage your hostels';
  static const String sysAdmin       = 'System administration';

  // Home
  static const String featuredHostels    = 'Featured Hostels';
  static const String recommended        = '✨  Recommended for You';
  static const String mostPopular        = '⭐  Most Popular';
  static const String budgetFriendly     = '🏷️  Budget Friendly — Under Rs. 15,000';
  static const String recentlyAdded      = '🆕  Recently Added';
  static const String recentlyViewed     = '🕒  Recently Viewed';
  static const String allListings        = '📍  All Listings in';
  static const String searchPlaceholder  = 'Search in';
  static const String selectCity         = 'Select City';

  // Hostel Details
  static const String overview       = 'Overview';
  static const String facilities     = 'Facilities';
  static const String roomTypes      = 'Room Types';
  static const String location       = 'Location';
  static const String hostedBy       = 'Hosted by';
  static const String reviews        = 'Reviews';
  static const String writeReview    = 'Write a Review';
  static const String cancel         = 'Cancel';
  static const String bookNow        = 'Book Now';
  static const String totalPrice     = 'TOTAL PRICE';
  static const String perMonth       = '/mo';
  static const String viewAll        = 'View All';
  static const String readMore       = 'Read More';

  // Booking
  static const String bookingSuccess = 'Booking Request Sent!';
  static const String bookingConfirmed = 'Booking Confirmed!';
  static const String bookingNote    = "Your request has been sent to the owner. You'll be notified once it's approved.";
  static const String redirecting    = 'Redirecting to your bookings...';
  static const String myBookings     = 'My Bookings';
  static const String bookingAll     = 'All';
  static const String bookingPending = 'Pending';
  static const String bookingApproved= 'Approved';
  static const String bookingHistory = 'History';

  // Profile
  static const String myProfile      = 'My Profile';
  static const String verifiedTenant = 'Verified Tenant';
  static const String activeBooking  = 'Active Booking';
  static const String savedHostels   = 'Saved Hostels';
  static const String paymentHistory = 'Payment History';
  static const String accountSettings= 'Account Settings';
  static const String editProfile    = 'Edit Profile';
  static const String termsConditions= 'Terms & Conditions';
  static const String helpCenter     = 'Help Center';
  static const String myActivity     = 'My Activity';
  static const String notifications  = 'Notifications';
  static const String support        = 'Support';
  static const String changePassword = 'Change Password';
  static const String submitComplaint= 'Submit Complaint';

  // Checkout
  static const String selectPaymentMethod = 'Select Payment Method';
  static const String easypaisa           = 'EasyPaisa';
  static const String jazzcash            = 'JazzCash';
  static const String cardPayment         = 'Card Payment';
  static const String payAtHostel         = 'Pay at Hostel';
  static const String easypaisaSubtitle   = 'Demo wallet payment for FYP';
  static const String jazzcashSubtitle    = 'Demo wallet payment for FYP';
  static const String cardPaymentSubtitle = 'Secure card checkout with Stripe';
  static const String payAtHostelSubtitle = 'No online payment required';
  static const String paymentPromptNote   = 'Demo mode: wallet payment is accepted for presentation without merchant API integration.';
  static const String cardPaymentNote     = 'You will be redirected to secure Stripe card checkout to complete this payment.';
  static const String confirmAndPay       = 'Confirm & Pay';
  static const String confirmBooking      = 'Confirm Booking';
  static const String submitBookingRequest = 'Submit';
  static const String paymentLockedUntilApproved = 'Payment will unlock after the hostel owner approves this booking request.';
  static const String payNow              = 'Pay Now';
  static const String cancelBooking       = 'Cancel Booking';

  // Owner
  static const String goodMorning    = 'Good Morning,';
  static const String activeRequests = 'Active Requests';
  static const String totalListings  = 'Total Listings';
  static const String pendingApproval= 'Pending Approval';
  static const String totalTenants   = 'Total Tenants';
  static const String addListing     = 'Add Listing';
  static const String viewReports    = 'View Reports';
  static const String recentActivity = 'Recent Activity';
  static const String bookingRequests= 'Booking Requests';
  static const String myListings     = 'My Listings';
  static const String accept         = 'Accept';
  static const String reject         = 'Reject';

  // Admin
  static const String adminDashboard = 'Admin Dashboard';
  static const String welcomeAdmin   = 'Welcome back, Admin';
  static const String totalUsers     = 'Total Users';
  static const String activeHostels  = 'Active Hostels';
  static const String pendingVerif   = 'Pending Verifications';
  static const String totalBookings  = 'Total Bookings';
  static const String pendingApprovals = 'Pending Approvals';
  static const String userManagement = 'User Management';
  static const String hostelManagement = 'Hostel Management';
  static const String platformSettings = 'Platform Settings';
  static const String approve        = 'Approve';
  static const String rejectAction   = 'Reject';

  // Nav
  static const String navHome        = 'Home';
  static const String navSaved       = 'Saved';
  static const String navBookings    = 'Bookings';
  static const String navProfile     = 'Profile';
  static const String navDashboard   = 'Dashboard';
  static const String navListings    = 'Listings';
  static const String navRequests    = 'Requests';
  static const String navOverview    = 'Overview';
  static const String navUsers       = 'Users';
  static const String navHostels     = 'Hostels';
  static const String navSettings    = 'Settings';
}
