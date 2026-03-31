<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- Key to look up station names by id -->
  <xsl:key name="station-by-id" match="station" use="@id"/>

  <!-- ============================================================
       ROOT TEMPLATE
  ============================================================ -->
  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Train Trips Report</title>
        <style>
          /* ---- Reset / Base ---- */
          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f4f8;
            color: #333;
            padding: 20px;
          }

          /* ---- Header ---- */
          header {
            background: linear-gradient(135deg, #1a3c5e, #2d6a9f);
            color: white;
            text-align: center;
            padding: 30px 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
          }
          header h1 { font-size: 2.2rem; letter-spacing: 1px; }
          header p  { margin-top: 6px; font-size: 0.95rem; opacity: 0.85; }

          /* ---- Line card ---- */
          .line-card {
            background: white;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            overflow: hidden;
          }
          .line-header {
            background: #1a3c5e;
            color: white;
            padding: 14px 20px;
            display: flex;
            align-items: center;
            gap: 12px;
          }
          .line-code {
            background: #2d6a9f;
            border-radius: 6px;
            padding: 4px 10px;
            font-weight: 700;
            font-size: 0.9rem;
            letter-spacing: 1px;
          }
          .line-route { font-size: 1.1rem; font-weight: 600; }
          .line-route .arrow { color: #f0a500; margin: 0 6px; }

          .line-body { padding: 20px; }
          .section-label {
            color: #2d6a9f;
            font-weight: 700;
            font-size: 0.85rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 14px;
            padding-bottom: 6px;
            border-bottom: 2px solid #e0eaf5;
          }

          /* ---- Trip block ---- */
          .trip-block { margin-bottom: 22px; }
          .trip-title {
            font-size: 0.95rem;
            font-weight: 700;
            color: #1a3c5e;
            margin-bottom: 8px;
          }
          .trip-title .sep { color: #999; margin: 0 6px; }
          .trip-title .city { color: #2d6a9f; }

          /* ---- Schedule table ---- */
          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.88rem;
            margin-bottom: 6px;
          }
          thead tr { background: #2d6a9f; color: white; }
          thead th {
            padding: 9px 14px;
            text-align: center;
            font-weight: 600;
            letter-spacing: 0.5px;
          }
          tbody tr { background: #f7f9fc; }
          tbody tr:nth-child(even) { background: #edf2f9; }
          tbody td {
            padding: 8px 14px;
            text-align: center;
            border-bottom: 1px solid #dde8f5;
          }

          /* ---- VIP badge ---- */
          .vip {
            color: #c8860a;
            font-weight: 700;
          }

          /* ---- Days badge ---- */
          .days {
            font-size: 0.78rem;
            color: #666;
            margin-top: 4px;
            margin-left: 2px;
          }
          .days span { font-weight: 600; color: #2d6a9f; }

          /* ---- Footer ---- */
          footer {
            text-align: center;
            margin-top: 30px;
            font-size: 0.8rem;
            color: #999;
          }
        </style>
      </head>
      <body>

        <header>
          <h1>&#128644; Train Trips Report</h1>
          <p>UMBB – FS | CS Department 2025/2026 | Module: L3 – DSS</p>
        </header>

        <main>
          <xsl:apply-templates select="transport/lines/line"/>
        </main>

        <footer>
          <p>Generated from transport.xml — Railway Trip Management Project</p>
        </footer>

      </body>
    </html>
  </xsl:template>

  <!-- ============================================================
       LINE TEMPLATE
  ============================================================ -->
  <xsl:template match="line">
    <xsl:variable name="dep" select="key('station-by-id', @departure)/@name"/>
    <xsl:variable name="arr" select="key('station-by-id', @arrival)/@name"/>

    <div class="line-card">
      <div class="line-header">
        <span class="line-code"><xsl:value-of select="@code"/></span>
        <span class="line-route">
          <xsl:value-of select="$dep"/>
          <span class="arrow">&#8594;</span>
          <xsl:value-of select="$arr"/>
        </span>
      </div>

      <div class="line-body">
        <div class="section-label">Detailed List of Trips</div>
        <xsl:apply-templates select="trips/trip">
          <xsl:with-param name="dep" select="$dep"/>
          <xsl:with-param name="arr" select="$arr"/>
        </xsl:apply-templates>
      </div>
    </div>
  </xsl:template>

  <!-- ============================================================
       TRIP TEMPLATE
  ============================================================ -->
  <xsl:template match="trip">
    <xsl:param name="dep"/>
    <xsl:param name="arr"/>

    <div class="trip-block">
      <div class="trip-title">
        Trip No. <xsl:value-of select="@code"/>
        <span class="sep">|</span>
        Departure: <span class="city"><xsl:value-of select="$dep"/></span>
        <span class="sep">|</span>
        Arrival: <span class="city"><xsl:value-of select="$arr"/></span>
      </div>

      <table>
        <thead>
          <tr>
            <th>Schedule</th>
            <th>Train Type</th>
            <th>Class</th>
            <th>Price (DA)</th>
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates select="class">
            <xsl:with-param name="schedule"
              select="concat(schedule/@departure, ' - ', schedule/@arrival)"/>
            <xsl:with-param name="type" select="@type"/>
          </xsl:apply-templates>
        </tbody>
      </table>

      <div class="days">
        &#128197; Operating days: <span><xsl:value-of select="days"/></span>
      </div>
    </div>
  </xsl:template>

  <!-- ============================================================
       CLASS TEMPLATE  (one table row per class)
  ============================================================ -->
  <xsl:template match="class">
    <xsl:param name="schedule"/>
    <xsl:param name="type"/>
    <tr>
      <td><xsl:value-of select="$schedule"/></td>
      <td><xsl:value-of select="$type"/></td>
      <td>
        <xsl:choose>
          <xsl:when test="@type = 'VIP'">
            <span class="vip">VIP</span>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
        </xsl:choose>
      </td>
      <td>
        <xsl:choose>
          <xsl:when test="@type = 'VIP'">
            <span class="vip"><xsl:value-of select="@price"/></span>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="@price"/></xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
