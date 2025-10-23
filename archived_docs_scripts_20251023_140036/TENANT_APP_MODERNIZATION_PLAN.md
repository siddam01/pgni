Module,Page,Test Case ID,Functionality/Feature,Test Steps,Expected Result,Actual Result,Pass/Fail,Priority,Remarks
Authentication,Login,TC-001,Login with valid credentials,"1. Enter email: priya@example.com
2. Enter password: Tenant@123
3. Click Login","User successfully logs in and redirects to Dashboard",,,"HIGH",""
Authentication,Login,TC-002,Login with invalid credentials,"1. Enter email: invalid@test.com
2. Enter password: wrong
3. Click Login","Error message: 'Invalid credentials'",,,"HIGH",""
Authentication,Login,TC-003,Login validation - empty fields,"1. Leave email empty
2. Click Login","Validation error: 'Email required'",,,"HIGH",""
Authentication,Logout,TC-004,Logout functionality,"1. Click logout button
2. Confirm logout","User logged out and redirected to login page",,,"HIGH",""
Dashboard,Dashboard,TC-005,Dashboard loads user data,"1. Login successfully
2. View dashboard","Dashboard displays: User name, Email, Hostel name",,,"HIGH",""
Dashboard,Dashboard,TC-006,Dashboard navigation cards,"1. View dashboard
2. Check all navigation cards","6 cards visible: Profile, Room, Bills, Issues, Notices, Settings",,,"MEDIUM",""
Profile,View Profile,TC-007,Profile displays user info,"1. Navigate to Profile
2. View all fields","Displays: Name, Email, Phone, Address, Room No, Rent, Emergency Contact",,,"HIGH",""
Profile,View Profile,TC-008,Profile image display,"1. Navigate to Profile
2. Check profile image","Profile image displays correctly or shows placeholder",,,"MEDIUM",""
Profile,View Profile,TC-009,Profile handles missing data,"1. Login with user having incomplete data
2. View profile","Missing fields show default text like 'Not provided'",,,"MEDIUM",""
Profile,Edit Profile,TC-010,Update profile name,"1. Navigate to Edit Profile
2. Change name to 'Test User'
3. Save","Name updates successfully, confirmation message shown",,,"HIGH",""
Profile,Edit Profile,TC-011,Update profile phone,"1. Navigate to Edit Profile
2. Change phone to '9876543210'
3. Save","Phone updates successfully",,,"HIGH",""
Profile,Edit Profile,TC-012,Profile validation - invalid phone,"1. Navigate to Edit Profile
2. Enter phone: '12345'
3. Save","Error: 'Invalid phone number'",,,"MEDIUM",""
Profile,Edit Profile,TC-013,Update emergency contact,"1. Navigate to Edit Profile
2. Update emergency contact details
3. Save","Emergency contact updates successfully",,,"MEDIUM",""
Bills,View Bills,TC-014,Bills list displays,"1. Navigate to Bills/Rents
2. View list","List of all bills/rents displays with: Amount, Date, Status",,,"HIGH",""
Bills,View Bills,TC-015,Bills filter by status,"1. Navigate to Bills
2. Filter by 'Paid'","Only paid bills display",,,"MEDIUM",""
Bills,View Bills,TC-016,Bills shows payment history,"1. Navigate to Bills
2. View payment history","Historical payments display with dates",,,"HIGH",""
Bills,View Bills,TC-017,Bills handles empty state,"1. Login with user having no bills
2. View Bills page","Message: 'No bills found'",,,"LOW",""
Bills,View Bills,TC-018,Bills total calculation,"1. Navigate to Bills
2. Check total amount","Total amount calculated correctly",,,"MEDIUM",""
Room,View Room,TC-019,Room details display,"1. Navigate to Room Details
2. View information","Displays: Room No, Rent, Floor, Capacity, Status, Amenities",,,"HIGH",""
Room,View Room,TC-020,Room amenities list,"1. Navigate to Room Details
2. View amenities section","All amenities listed (AC, WiFi, etc.)",,,"MEDIUM",""
Room,View Room,TC-021,Room photo gallery,"1. Navigate to Room Details
2. View photos","Room photos display in gallery",,,"LOW",""
Room,View Room,TC-022,Room handles no photos,"1. Navigate to room with no photos
2. View Room Details","Placeholder image or message shown",,,"LOW",""
Room,View Room,TC-023,Room shows roommates,"1. Navigate to Room Details
2. View roommates section","List of roommates displays (if applicable)",,,"MEDIUM",""
Issues,Report Issue,TC-024,Create new issue,"1. Navigate to Issues
2. Click 'Report Issue'
3. Fill form: Title, Description, Type
4. Submit","Issue created successfully, confirmation shown",,,"HIGH",""
Issues,Report Issue,TC-025,Issue validation - empty title,"1. Navigate to Issues
2. Click 'Report Issue'
3. Leave title empty
4. Submit","Error: 'Title required'",,,"HIGH",""
Issues,View Issues,TC-026,Issues list displays,"1. Navigate to Issues
2. View list","All reported issues display with: Title, Status, Date",,,"HIGH",""
Issues,View Issues,TC-027,Issues filter by status,"1. Navigate to Issues
2. Filter by 'Pending'","Only pending issues display",,,"MEDIUM",""
Issues,View Issues,TC-028,Issue details view,"1. Navigate to Issues
2. Click on an issue","Issue details page opens with full information",,,"MEDIUM",""
Issues,View Issues,TC-029,Issues handles empty state,"1. Login with user having no issues
2. View Issues page","Message: 'No issues reported'",,,"LOW",""
Notices,View Notices,TC-030,Notices list displays,"1. Navigate to Notices
2. View list","All notices display with: Title, Date, Priority",,,"MEDIUM",""
Notices,View Notices,TC-031,Notice details view,"1. Navigate to Notices
2. Click on a notice","Notice details page opens with full content",,,"MEDIUM",""
Notices,View Notices,TC-032,Notices sorted by date,"1. Navigate to Notices
2. Check order","Notices sorted by date (newest first)",,,"LOW",""
Notices,View Notices,TC-033,Notices handles empty state,"1. Login with user having no notices
2. View Notices page","Message: 'No notices available'",,,"LOW",""
Documents,View Documents,TC-034,Documents list displays,"1. Navigate to Documents
2. View list","All uploaded documents display with: Name, Type, Date",,,"MEDIUM",""
Documents,Upload Document,TC-035,Upload new document,"1. Navigate to Documents
2. Click 'Upload'
3. Select file
4. Add title
5. Upload","Document uploads successfully, appears in list",,,"MEDIUM",""
Documents,Upload Document,TC-036,Upload validation - file size,"1. Navigate to Documents
2. Try uploading file > 5MB","Error: 'File size too large'",,,"LOW",""
Documents,View Documents,TC-037,Download document,"1. Navigate to Documents
2. Click download icon on a document","Document downloads successfully",,,"LOW",""
Documents,View Documents,TC-038,Delete document,"1. Navigate to Documents
2. Click delete on a document
3. Confirm","Document deleted successfully",,,"LOW",""
Settings,App Settings,TC-039,View settings page,"1. Navigate to Settings
2. View all options","Settings page displays: Profile, Notifications, About, Logout",,,"LOW",""
Settings,App Settings,TC-040,Change hostel (if applicable),"1. Navigate to Settings
2. Change hostel
3. Save","Hostel changes, data reloads",,,"LOW",""
Settings,App Settings,TC-041,View app version,"1. Navigate to Settings
2. Scroll to bottom","App version displays correctly",,,"LOW",""
Settings,App Settings,TC-042,Logout from settings,"1. Navigate to Settings
2. Click Logout
3. Confirm","User logged out successfully",,,"HIGH",""
General,Navigation,TC-043,Bottom navigation works,"1. Login
2. Click each navigation tab","Each tab navigates to correct page",,,"HIGH",""
General,Navigation,TC-044,Back button works,"1. Navigate to any page
2. Press back button","Returns to previous page",,,"MEDIUM",""
General,Network,TC-045,App handles no internet,"1. Disable internet
2. Try loading any page","Error message: 'No internet connection'",,,"HIGH",""
General,Network,TC-046,App recovers after internet restored,"1. Disable internet
2. Enable internet
3. Retry","App successfully loads data",,,"HIGH",""
General,Performance,TC-047,App loads in reasonable time,"1. Login
2. Navigate to any page","Page loads within 3 seconds",,,"MEDIUM",""
General,UI/UX,TC-048,All buttons are clickable,"1. Navigate through app
2. Test all buttons","All buttons respond to clicks",,,"HIGH",""
General,UI/UX,TC-049,Text is readable,"1. Navigate through app
2. Check all text","All text is readable, proper font size",,,"MEDIUM",""
General,UI/UX,TC-050,Images load correctly,"1. Navigate to pages with images
2. Check all images","All images load without errors",,,"MEDIUM",""

