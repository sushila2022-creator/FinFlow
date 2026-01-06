# Fix Dashboard Layout Issues - Todo List

## Objective
Fix the Dashboard layout issues in lib/screens/dashboard_screen.dart according to specified structure, styling, and sample data requirements.

## Requirements Analysis
1. **Structure**: Main Column children order:
   - Balance Card (Top)
   - SizedBox(height: 20)
   - Tabs/Chips (wrapped in SizedBox(height: 50))
   - SizedBox(height: 10)
   - Transaction List (wrapped in Expanded)

2. **Styling**: 
   - ChoiceChip widgets (Teal when selected, Grey outline when not)
   - Transaction List padding for screen edge spacing

3. **Icons**: Sample data category names must match icon logic

## Todo Checklist

- [ ] Analyze current dashboard structure and identify layout issues
- [ ] Reorder main Column children to match requirements (Balance Card first)
- [ ] Add correct SizedBox spacing (20, 50, 10)
- [ ] Wrap Transaction List in Expanded widget
- [ ] Ensure ChoiceChip styling (Teal selected, Grey outline unselected)
- [ ] Update sample data category names to match icon logic
- [ ] Add padding to Transaction List to prevent screen edge touching
- [ ] Test the changes and verify layout works correctly
