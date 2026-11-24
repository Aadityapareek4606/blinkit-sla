"""Builds blinkit_sla_analysis.xlsx from focus_delivery_minutes.csv and cluster_band_cells.csv.
Raw data is copied in as inputs; every calculated cell is a live Excel formula."""
import csv
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.formatting.rule import CellIsRule
from openpyxl.utils import get_column_letter

FONT = "Arial"
base = Font(name=FONT, size=10)
bold = Font(name=FONT, size=10, bold=True)
hdr_font = Font(name=FONT, size=10, bold=True, color="FFFFFF")
hdr_fill = PatternFill("solid", start_color="1F3864")
tot_fill = PatternFill("solid", start_color="D9E1F2")
thin = Side(style="thin", color="BFBFBF")
box = Border(left=thin, right=thin, top=thin, bottom=thin)

def read(path):
    with open(path, newline="") as f:
        r = list(csv.reader(f))
    return r[0], r[1:]

def header(ws, row, labels):
    for i, lab in enumerate(labels, 1):
        c = ws.cell(row=row, column=i, value=lab)
        c.font, c.fill, c.border = hdr_font, hdr_fill, box
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

def num(v):
    try:
        return float(v) if "." in v else int(v)
    except ValueError:
        return v

wb = Workbook()

# ---------------- Sheet 1: Focus Minutes
fh, frows = read("focus_delivery_minutes.csv")
ws1 = wb.active
ws1.title = "Focus Minutes"
header(ws1, 1, fh)
for r, row in enumerate(frows, 2):
    for c, v in enumerate(row, 1):
        cell = ws1.cell(row=r, column=c, value=num(v))
        cell.font = base
for col, w in zip("ABCDE", [10, 14, 12, 24, 18]):
    ws1.column_dimensions[col].width = w
ws1.freeze_panes = "A2"
assert len(frows) == 780

# contiguous blocks by cell_label (rows are ordered by cluster, band, order_id)
blocks = {}
for i, row in enumerate(frows, 2):
    lab = row[3]
    lo, hi = blocks.get(lab, (i, i))
    blocks[lab] = (lo, i)
for lab, (lo, hi) in blocks.items():
    assert all(frows[j - 2][3] == lab for j in range(lo, hi + 1)), "block not contiguous"

# ---------------- Sheet 2: Cells
ch, crows = read("cluster_band_cells.csv")
ws2 = wb.create_sheet("Cells")
header(ws2, 1, ch)
for r, row in enumerate(crows, 2):
    for c, v in enumerate(row, 1):
        cell = ws2.cell(row=r, column=c, value=num(v))
        cell.font = base
        if ch[c - 1] in ("compliance_pct", "avg_minutes"):
            cell.number_format = "0.00"
for i, w in enumerate([11, 14, 12, 26, 16, 18, 16, 13, 13, 14], 1):
    ws2.column_dimensions[get_column_letter(i)].width = w
ws2.freeze_panes = "A2"
assert len(crows) == 24 and ch[3] == "cell_label" and ch[6] == "compliance_pct"

# ---------------- Sheet 3: Cell Stats
ws3 = wb.create_sheet("Cell Stats")
cols = ["cell_label", "n", "mean", "median", "min", "max", "sd", "standard_error",
        "margin_of_error", "ci_low", "ci_high", "mean_minus_median", "p_within_10",
        "p_over_10", "p_strictly_under_10", "boundary_gap_pts", "Matches Part B?"]
header(ws3, 1, cols)
order = ["Andheri - Evening", "Whitefield - Lunch", "Thane - Morning"]
for r, lab in enumerate(order, 2):
    lo, hi = blocks[lab]
    blk = f"'Focus Minutes'!$E${lo}:$E${hi}"
    ws3.cell(row=r, column=1, value=lab)
    f = {
        2:  f"=COUNT({blk})",
        3:  f"=AVERAGE({blk})",
        4:  f"=MEDIAN({blk})",
        5:  f"=MIN({blk})",
        6:  f"=MAX({blk})",
        7:  f"=STDEV({blk})",
        8:  f"=G{r}/SQRT(B{r})",
        9:  f"=1.96*H{r}",
        10: f"=C{r}-I{r}",
        11: f"=C{r}+I{r}",
        12: f"=C{r}-D{r}",
        13: f'=COUNTIF({blk},"<=10")/COUNT({blk})',
        14: f"=1-M{r}",
        15: f'=COUNTIF({blk},"<10")/COUNT({blk})',
        16: f"=(M{r}-O{r})*100",
        17: f'=IF(ROUND(M{r}*100,2)=_xlfn.XLOOKUP(A{r},Cells!$D$2:$D$25,Cells!$G$2:$G$25),"Yes","No")',
    }
    for c, formula in f.items():
        ws3.cell(row=r, column=c, value=formula)
    fmts = {2: "0", 3: "0.000", 4: "0.0", 5: "0", 6: "0", 7: "0.000", 8: "0.000", 9: "0.000",
            10: "0.000", 11: "0.000", 12: "0.000", 13: "0.0000", 14: "0.0000", 15: "0.0000", 16: "0.00"}
    for c in range(1, 18):
        cell = ws3.cell(row=r, column=c)
        cell.font, cell.border = base, box
        if c in fmts:
            cell.number_format = fmts[c]
        if c == 17:
            cell.alignment = Alignment(horizontal="center")
ws3.column_dimensions["A"].width = 22
for i in range(2, 18):
    ws3.column_dimensions[get_column_letter(i)].width = 15
ws3.row_dimensions[1].height = 32
ws3.freeze_panes = "B2"
notes = [
    "Notes",
    "Data: 'Focus Minutes' holds delivered orders for the three focus cells (copied from focus_delivery_minutes.csv, export of 03_segments cells).",
    "Each row reads its own contiguous block in 'Focus Minutes' column E; sd uses STDEV (sample standard deviation).",
    "margin_of_error = 1.96 x standard_error (approximate 95% confidence interval for the mean, normal approximation).",
    "p_within_10 uses <= 10 (the KPI boundary); p_strictly_under_10 uses < 10; boundary_gap_pts is the difference in percentage points.",
    "Matches Part B? compares p_within_10 x 100 (rounded to 2 dp) with compliance_pct in 'Cells' using XLOOKUP (needs Excel 2021/365 or Google Sheets).",
    "Older Excel or LibreOffice alternative: =IF(ROUND(M2*100,2)=INDEX(Cells!$G$2:$G$25,MATCH(A2,Cells!$D$2:$D$25,0)),\"Yes\",\"No\")",
]
for i, t in enumerate(notes):
    c = ws3.cell(row=6 + i, column=1, value=t)
    c.font = bold if i == 0 else base

# ---------------- Sheet 4: Heat Table
ws4 = wb.create_sheet("Heat Table")
ws4["A1"] = "Sub-10-Minute Compliance (%) by cluster and hour band"
ws4["A1"].font = Font(name=FONT, size=12, bold=True)
ws4["A2"] = "Source: 'Cells' sheet. Cell values use SUMIFS; totals are weighted (within-SLA orders / delivered orders). Red < 60, amber 60 to < 80."
ws4["A2"].font = Font(name=FONT, size=9, italic=True)
bands = ["Morning", "Lunch", "Afternoon", "Evening"]
clusters = ["Andheri", "Powai", "Thane", "Koramangala", "Indiranagar", "Whitefield"]
header(ws4, 4, ["Cluster"] + bands + ["All bands"])
for i, cl in enumerate(clusters):
    r = 5 + i
    ws4.cell(row=r, column=1, value=cl).font = bold
    for j in range(4):
        col = get_column_letter(2 + j)
        ws4.cell(row=r, column=2 + j,
                 value=f"=SUMIFS(Cells!$G$2:$G$25,Cells!$B$2:$B$25,$A{r},Cells!$C$2:$C$25,{col}$4)")
    ws4.cell(row=r, column=6,
             value=f"=ROUND(100*SUMIFS(Cells!$F$2:$F$25,Cells!$B$2:$B$25,$A{r})/SUMIFS(Cells!$E$2:$E$25,Cells!$B$2:$B$25,$A{r}),2)")
tr = 5 + len(clusters)  # total row = 11
ws4.cell(row=tr, column=1, value="All clusters").font = bold
for j in range(4):
    col = get_column_letter(2 + j)
    ws4.cell(row=tr, column=2 + j,
             value=f"=ROUND(100*SUMIFS(Cells!$F$2:$F$25,Cells!$C$2:$C$25,{col}$4)/SUMIFS(Cells!$E$2:$E$25,Cells!$C$2:$C$25,{col}$4),2)")
ws4.cell(row=tr, column=6, value="=ROUND(100*SUM(Cells!$F$2:$F$25)/SUM(Cells!$E$2:$E$25),2)")
for r in range(5, tr + 1):
    for c in range(1, 7):
        cell = ws4.cell(row=r, column=c)
        cell.border = box
        if c > 1:
            cell.number_format = "0.00"
            cell.alignment = Alignment(horizontal="center")
            if cell.font != bold:
                cell.font = base
        if r == tr or c == 6:
            cell.fill = tot_fill
            cell.font = bold
red = PatternFill("solid", start_color="F8696B", end_color="F8696B")
amber = PatternFill("solid", start_color="FFD966", end_color="FFD966")
rng = f"B5:E{tr - 1}"
ws4.conditional_formatting.add(rng, CellIsRule(operator="lessThan", formula=["60"], fill=red))
ws4.conditional_formatting.add(rng, CellIsRule(operator="between", formula=["60", "79.9999999"], fill=amber))
cr = tr + 2  # 13
ws4.cell(row=cr, column=1, value="Cells below 60").font = bold
ws4.cell(row=cr, column=2, value=f'=COUNTIF({rng},"<60")')
ws4.cell(row=cr + 1, column=1, value="Cells below 80").font = bold
ws4.cell(row=cr + 1, column=2, value=f'=COUNTIF({rng},"<80")')
ws4.cell(row=cr + 2, column=1, value="Cells 60 to < 80").font = bold
ws4.cell(row=cr + 2, column=2, value=f"=B{cr+1}-B{cr}")
for r in range(cr, cr + 3):
    ws4.cell(row=r, column=2).font = base
    ws4.cell(row=r, column=2).alignment = Alignment(horizontal="center")
    ws4.cell(row=r, column=2).number_format = "0"
ws4.column_dimensions["A"].width = 18
for col in "BCDEF":
    ws4.column_dimensions[col].width = 13
ws4.freeze_panes = "B5"

wb.calculation.fullCalcOnLoad = True
wb.save("blinkit_sla_analysis.xlsx")
print("saved", blocks)
