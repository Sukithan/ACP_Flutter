# Visual Design & Color Standards

## Color Palette

### Primary Colors
```dart
- Primary Color: Colors.deepPurple (Theme color)
- Background: Colors.white
- Cards: Colors.white with elevation
- Input Fields: Colors.grey.shade50
```

### Status Colors
```dart
// Project Status
Active      → Colors.green      (#4CAF50)
On Hold     → Colors.orange     (#FF9800)
Completed   → Colors.blue       (#2196F3)

// Task Status
Pending     → Colors.orange     (#FF9800)
In Progress → Colors.blue       (#2196F3)
Completed   → Colors.green      (#4CAF50)
```

### Priority Colors
```dart
High        → Colors.red        (#F44336)
Medium      → Colors.orange     (#FF9800)
Low         → Colors.green      (#4CAF50)
```

### Role Colors
```dart
Admin       → Colors.red        (#F44336)
Manager     → Colors.blue       (#2196F3)
Employee    → Colors.green      (#4CAF50)
```

### Severity Colors (Logs)
```dart
Error       → Colors.red        (#F44336)
Warning     → Colors.orange     (#FF9800)
Info        → Colors.blue       (#2196F3)
Debug       → Colors.grey       (#9E9E9E)
```

## Component Standards

### Cards
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: ...
  ),
)
```

### Chips
```dart
// Status Chip
Chip(
  label: Text('STATUS'),
  backgroundColor: statusColor.withOpacity(0.2),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
)

// Priority Chip
Chip(
  avatar: Icon(Icons.flag, color: priorityColor),
  label: Text('PRIORITY'),
  backgroundColor: priorityColor.withOpacity(0.2),
)
```

### Buttons
```dart
// Primary Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
  ),
  child: Text('ACTION'),
)

// Secondary Button
TextButton.icon(
  icon: Icon(Icons.add),
  label: Text('ACTION'),
)
```

### Statistics Card
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Icon(icon, size: 40, color: color),
        SizedBox(height: 12),
        Text(value, style: headlineMedium),
        Text(label, style: bodySmall),
      ],
    ),
  ),
)
```

### Progress Bar
```dart
LinearProgressIndicator(
  value: percentage,
  backgroundColor: color.withOpacity(0.2),
  valueColor: AlwaysStoppedAnimation(color),
  minHeight: 8,
  borderRadius: BorderRadius.circular(4),
)
```

### List Item
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor: color,
      child: Text(initial),
    ),
    title: Text(title, style: fontWeight: FontWeight.bold),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description),
        Chip(...),
      ],
    ),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
    isThreeLine: true,
  ),
)
```

### Welcome Card (Dashboard)
```dart
Card(
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        CircleAvatar(...),
        Column(
          children: [
            Text('Welcome back'),
            Text(userName),
            Wrap(children: roleChips),
          ],
        ),
      ],
    ),
  ),
)
```

### Empty State
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 60, color: Colors.grey),
      SizedBox(height: 16),
      Text('No items found'),
    ],
  ),
)
```

### Error State
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline, size: 60, color: Colors.red),
      SizedBox(height: 16),
      Text('Error: $message'),
      SizedBox(height: 16),
      ElevatedButton(
        onPressed: retry,
        child: Text('Retry'),
      ),
    ],
  ),
)
```

## Typography

### Text Styles
```dart
// Page Title
Theme.of(context).textTheme.headlineSmall?.copyWith(
  fontWeight: FontWeight.bold,
)

// Section Title
Theme.of(context).textTheme.titleLarge?.copyWith(
  fontWeight: FontWeight.bold,
)

// Card Title
Theme.of(context).textTheme.titleMedium?.copyWith(
  fontWeight: FontWeight.bold,
)

// Body Text
Theme.of(context).textTheme.bodyLarge

// Caption
Theme.of(context).textTheme.bodySmall
```

## Icons

### Common Icons
```dart
Dashboard       → Icons.dashboard
Projects        → Icons.folder
Tasks           → Icons.task
Users           → Icons.people
Settings        → Icons.settings
Profile         → Icons.person
Notifications   → Icons.notifications_outlined
Add             → Icons.add
Edit            → Icons.edit
Delete          → Icons.delete
Refresh         → Icons.refresh
Logout          → Icons.logout
Health          → Icons.health_and_safety
Logs            → Icons.article
Calendar        → Icons.calendar_today
Priority        → Icons.flag
Status          → Icons.circle
Info            → Icons.info_outline
Error           → Icons.error_outline
Warning         → Icons.warning
Success         → Icons.check_circle
```

## Spacing

### Standard Spacing
```dart
Small Gap       → 4.0
Normal Gap      → 8.0
Medium Gap      → 12.0
Large Gap       → 16.0
Extra Large     → 20.0
Section Gap     → 24.0
```

### Padding
```dart
Card Padding    → EdgeInsets.all(16)
List Padding    → EdgeInsets.all(8)
Screen Padding  → EdgeInsets.all(16)
Form Padding    → EdgeInsets.all(16)
```

### Margins
```dart
List Item       → EdgeInsets.symmetric(horizontal: 8, vertical: 4)
Card            → EdgeInsets.symmetric(horizontal: 8, vertical: 4)
Button          → EdgeInsets.symmetric(vertical: 16)
```

## Grid Layouts

### Statistics Grid
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.3,
  ),
)
```

### Quick Actions Grid
```dart
GridView.count(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 1.8,
)
```

## Animations

### Loading
```dart
CircularProgressIndicator()
// or for buttons
SizedBox(
  height: 20,
  width: 20,
  child: CircularProgressIndicator(strokeWidth: 2),
)
```

### Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: loadData,
  child: ListView(...),
)
```

## Forms

### Text Field
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Hint',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.icon),
  ),
  validator: (value) => ...,
)
```

### Dropdown
```dart
DropdownButtonFormField<T>(
  decoration: InputDecoration(
    labelText: 'Label',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.icon),
  ),
  items: items,
  onChanged: (value) => ...,
  validator: (value) => ...,
)
```

### Date Picker
```dart
InkWell(
  onTap: selectDate,
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: 'Date',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.calendar_today),
    ),
    child: Text(formattedDate),
  ),
)
```

## Dialog Standards

### Confirmation Dialog
```dart
AlertDialog(
  title: Text('Confirm Action'),
  content: Text('Are you sure?'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text('Cancel'),
    ),
    ElevatedButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text('Confirm'),
    ),
  ],
)
```

### Selection Dialog
```dart
AlertDialog(
  title: Text('Select Option'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: options.map((option) {
      return RadioListTile<T>(
        title: Text(option.label),
        value: option.value,
        groupValue: currentValue,
        onChanged: (value) => Navigator.pop(context, value),
      );
    }).toList(),
  ),
)
```

## SnackBar Messages

### Success
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success message'),
    backgroundColor: Colors.green,
  ),
)
```

### Error
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error message'),
    backgroundColor: Colors.red,
  ),
)
```

### Info
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Info message')),
)
```

---

**Note**: All color values use Material Design colors for consistency. Custom colors should be added to a constants file if needed frequently.
