#!/usr/bin/env python3
"""Generate Word document for AWS database environments session notes."""

from docx import Document
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT

OUTPUT = "/Users/lunga.ndzimande/Documents/AWS-Database-Environments-Session-Notes.docx"


def set_cell_text(cell, text, bold=False):
    cell.text = ""
    p = cell.paragraphs[0]
    run = p.add_run(text)
    run.bold = bold
    run.font.size = Pt(10)


def add_table(doc, headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(headers):
        set_cell_text(table.rows[0].cells[i], h, bold=True)
    for r_idx, row in enumerate(rows):
        for c_idx, val in enumerate(row):
            set_cell_text(table.rows[r_idx + 1].cells[c_idx], val)
    doc.add_paragraph()


def main():
    doc = Document()

    # Title
    title = doc.add_heading("AWS Database Environments — Session Notes", 0)
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER

    sub = doc.add_paragraph("Overview & knowledge transfer (anonymized)")
    sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sub.runs[0].italic = True

    doc.add_paragraph(
        "This document summarizes an introductory session on database environments "
        "in AWS. No company, product, or person names are included."
    )

    # Why this session
    doc.add_heading("Why this session exists", level=1)
    doc.add_paragraph("Purpose: High-level map of database/AWS environments — not deep dives.", style="List Bullet")
    doc.add_paragraph("Deeper sessions planned separately for:", style="List Bullet")
    doc.add_paragraph("App A → dedicated session on SingleStore", style="List Bullet 2")
    doc.add_paragraph("App B → dedicated session on RDS MySQL", style="List Bullet 2")
    doc.add_paragraph("Data structure / schema intro for each app", style="List Bullet 2")
    doc.add_paragraph(
        "Recordings and transcripts are the main reference when you need answers later.",
        style="List Bullet",
    )

    # Main idea
    doc.add_heading("Main idea (one sentence)", level=1)
    doc.add_paragraph(
        "Two primary apps run in AWS with dev/release in one region and production "
        "in three regions; there is also a legacy SQL Server environment still in "
        "support, and one decommissioned complex setup you can skip."
    )

    # Environment map
    doc.add_heading("Environment map (at a glance)", level=1)
    add_table(
        doc,
        ["Layer", "Dev / Release", "Production (×3)"],
        [
            ["App B (MySQL/RDS)", "Region A (e.g. Ireland)", "Frankfurt, US East, London"],
            ["App A (SingleStore)", "Same pattern", "Same three prod regions"],
        ],
    )
    doc.add_paragraph(
        "Regions to remember: one home region for non-prod; prod split across EU (2) + US (1)."
    )

    # Documentation page
    doc.add_heading("Documentation page (inventory wiki)", level=1)
    for item in [
        "Lists EC2 instances, clusters, versions for quick reference.",
        "May be outdated — team updates when they can; not always first priority.",
        "Example: After a SingleStore upgrade to v8.9.9, new servers were created, then rolled back — rollback servers may still appear on the page.",
        "Takeaway: Treat the page as a starting point; verify in AWS/console if something looks stale.",
    ]:
        doc.add_paragraph(item, style="List Bullet")

    # App B
    doc.add_heading("App B — MySQL / RDS", level=1)
    doc.add_paragraph("Dev + Release in non-prod region", style="List Bullet")
    doc.add_paragraph("Three production deployments (Frankfurt, US, London)", style="List Bullet")
    doc.add_paragraph("Details: RDS MySQL — covered in a future session.")

    # App A
    doc.add_heading("App A — SingleStore", level=1)
    doc.add_paragraph("Same regional pattern as App B", style="List Bullet")
    doc.add_paragraph("Dev/Release in non-prod; prod in London, Frankfurt, US", style="List Bullet")
    doc.add_paragraph("Details: SingleStore clusters — separate KT session.")

    # Decommissioned
    doc.add_heading("Legacy environment — decommissioned (skip)", level=1)
    for item in [
        "Was a complex write on SQL Server → CDC/sync → read from SingleStore pattern.",
        "Decommissioned shortly before onboarding — not in support anymore.",
        "Do not spend time learning this unless asked for historical context.",
    ]:
        doc.add_paragraph(item, style="List Bullet")

    # Encore
    doc.add_heading("Still in support: Encore (SQL Server)", level=1)
    doc.add_paragraph("Microsoft SQL Server environment (not MySQL/SingleStore).", style="List Bullet")
    doc.add_paragraph("Some prior SQL Server exposure — deeper Encore KT may follow.", style="List Bullet")

    # Action items
    doc.add_heading("Action items", level=1)
    add_table(
        doc,
        ["#", "What", "When"],
        [
            ["1", "Bookmark the environment inventory page", "Now"],
            ["2", "Attend App A / SingleStore KT", "Scheduled"],
            ["3", "Attend App B / RDS MySQL KT", "Scheduled"],
            ["4", "Attend data structure sessions per app", "Scheduled"],
            ["5", "If wiki looks wrong, check live infra or ask the team", "As needed"],
        ],
    )

    # Mental model
    doc.add_heading("Quick mental model", level=1)
    diagram = """                    ┌─────────────────┐
                    │  Inventory wiki  │  ← snapshot (may be stale)
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   App B (RDS)         App A (SingleStore)    Encore (SQL Server)
   dev/release         dev/release            still active
   + 3× prod           + 3× prod
        │                    │
        └──────── same 3 prod regions ────────┘

   [Decommissioned legacy]  SQL Server → sync → SingleStore  ← ignore"""
    p = doc.add_paragraph()
    run = p.add_run(diagram)
    run.font.name = "Courier New"
    run.font.size = Pt(9)

    # Terms
    doc.add_heading("Terms (plain English)", level=1)
    add_table(
        doc,
        ["Term", "Meaning here"],
        [
            ["Dev / Release", "Non-production; test and pre-prod"],
            ["Production ×3", "Same app, three geographic deployments"],
            ["SingleStore", "Distributed SQL/analytics DB (App A)"],
            ["RDS MySQL", "Managed MySQL on AWS (App B)"],
            ["CDC / sync", "Changes copied from one DB to another (legacy setup)"],
            ["Rollback", "Upgrade failed; reverted to previous servers"],
        ],
    )

    doc.add_paragraph()
    footer = doc.add_paragraph("Generated for personal reference. Anonymized — no sensitive identifiers.")
    footer.runs[0].italic = True
    footer.runs[0].font.size = Pt(9)

    doc.save(OUTPUT)
    print(f"Created: {OUTPUT}")


if __name__ == "__main__":
    main()
