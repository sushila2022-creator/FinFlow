# Transaction List Layout Fix - Task Plan

## Goal
Fix text truncation issue in Transaction List where category names are cut off (e.g., 'sal...').

## Steps
- [ ] Analyze current transaction list implementation
- [ ] Locate the specific file containing the transaction list layout
- [ ] Implement the exact Row layout as specified
- [ ] Apply proper styling and spacing
- [ ] Test the layout changes
- [ ] Verify the outcome matches the specification

## Layout Requirements
- Left: CircleAvatar Icon + SizedBox(width: 12)
- Middle: Expanded widget wrapping Category Name Text
  - Style: fontWeight: FontWeight.w600, fontSize: 15
  - overflow: TextOverflow.ellipsis
- Right Side Group: Row with mainAxisSize: MainAxisSize.min
  - Date Text ('Dec 16', grey, small)
  - SizedBox(width: 8)
  - Amount Text (Bold, Green/Red)
  - PopupMenuButton (if kept)

## Expected Outcome
Layout: [Icon] Salary Name.............. [Dec 16 +5000]
