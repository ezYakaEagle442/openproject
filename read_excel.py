import openpyxl
import sys

# Load the Excel file
wb = openpyxl.load_workbook('path/to/your/excel.xlsx')
sheet = wb.active

# Iterate through rows and print user data
for row in sheet.iter_rows(min_row=2, values_only=True):
    # Print_department|name surname|role
    print('|'.join(filter(None, row)))

