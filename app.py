"""
Railway Trip Management — Flask Web Application
UMBB | L3 DSS Project 2025/2026

APIs used:
  • xml.dom.minidom  (DOM)  → display complete trip details
  • xml.etree.ElementTree   → statistics (cheapest/most expensive, count by type)
"""

from flask import Flask, render_template, request
import xml.dom.minidom as minidom
import xml.etree.ElementTree as ET

# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────
XML_FILE = "transport.xml"

app = Flask(__name__)


# ─────────────────────────────────────────────
# Helper: build station id→name map (ET)
# ─────────────────────────────────────────────
def get_stations_et():
    tree = ET.parse(XML_FILE)
    root = tree.getroot()
    return {s.get("id"): s.get("name") for s in root.findall("stations/station")}


# ─────────────────────────────────────────────
# Helper: build station id→name map (DOM)
# ─────────────────────────────────────────────
def get_stations_dom(dom):
    return {
        s.getAttribute("id"): s.getAttribute("name")
        for s in dom.getElementsByTagName("station")
    }


# ─────────────────────────────────────────────
# Helper: extract all trips as plain dicts (ET)
# ─────────────────────────────────────────────
def get_all_trips_et():
    stations = get_stations_et()
    tree = ET.parse(XML_FILE)
    root = tree.getroot()
    trips = []
    for line in root.findall("lines/line"):
        dep_name = stations.get(line.get("departure"), line.get("departure"))
        arr_name = stations.get(line.get("arrival"),   line.get("arrival"))
        for trip in line.findall("trips/trip"):
            sched = trip.find("schedule")
            classes = [
                {"type": c.get("type"), "price": int(c.get("price"))}
                for c in trip.findall("class")
            ]
            trips.append({
                "line_code":  line.get("code"),
                "departure":  dep_name,
                "arrival":    arr_name,
                "code":       trip.get("code"),
                "type":       trip.get("type"),
                "sched_dep":  sched.get("departure") if sched is not None else "–",
                "sched_arr":  sched.get("arrival")   if sched is not None else "–",
                "classes":    classes,
                "min_price":  min(c["price"] for c in classes),
                "days":       trip.findtext("days", default=""),
            })
    return trips


# ─────────────────────────────────────────────
# Helper: complete DOM detail for ONE trip
# ─────────────────────────────────────────────
def get_trip_dom(trip_code):
    dom      = minidom.parse(XML_FILE)
    stations = get_stations_dom(dom)
    result   = None

    for line_el in dom.getElementsByTagName("line"):
        for trip_el in line_el.getElementsByTagName("trip"):
            if trip_el.getAttribute("code") == trip_code:
                sched_els = trip_el.getElementsByTagName("schedule")
                sched     = sched_els[0] if sched_els else None
                classes   = [
                    {
                        "type":  c.getAttribute("type"),
                        "price": c.getAttribute("price"),
                    }
                    for c in trip_el.getElementsByTagName("class")
                ]
                days_els = trip_el.getElementsByTagName("days")
                days     = days_els[0].firstChild.nodeValue if days_els else ""

                result = {
                    "code":      trip_el.getAttribute("code"),
                    "type":      trip_el.getAttribute("type"),
                    "line_code": line_el.getAttribute("code"),
                    "departure": stations.get(line_el.getAttribute("departure"), "?"),
                    "arrival":   stations.get(line_el.getAttribute("arrival"),   "?"),
                    "sched_dep": sched.getAttribute("departure") if sched else "–",
                    "sched_arr": sched.getAttribute("arrival")   if sched else "–",
                    "classes":   classes,
                    "days":      days,
                }
                break
        if result:
            break
    return result


# ─────────────────────────────────────────────
# Statistics via ElementTree
# ─────────────────────────────────────────────
def get_statistics():
    stations = get_stations_et()
    tree     = ET.parse(XML_FILE)
    root     = tree.getroot()

    line_stats    = []
    type_counter  = {}

    for line in root.findall("lines/line"):
        dep  = stations.get(line.get("departure"), line.get("departure"))
        arr  = stations.get(line.get("arrival"),   line.get("arrival"))
        all_prices = []

        cheapest   = None
        most_exp   = None
        cheap_p    = float("inf")
        exp_p      = float("-inf")

        for trip in line.findall("trips/trip"):
            t_type = trip.get("type", "Unknown")
            type_counter[t_type] = type_counter.get(t_type, 0) + 1

            for cls in trip.findall("class"):
                price = int(cls.get("price", 0))
                all_prices.append(price)
                if price < cheap_p:
                    cheap_p   = price
                    cheapest  = {"trip": trip.get("code"), "class": cls.get("type"), "price": price}
                if price > exp_p:
                    exp_p     = price
                    most_exp  = {"trip": trip.get("code"), "class": cls.get("type"), "price": price}

        line_stats.append({
            "code":      line.get("code"),
            "departure": dep,
            "arrival":   arr,
            "cheapest":  cheapest,
            "most_exp":  most_exp,
            "num_trips": len(line.findall("trips/trip")),
        })

    return line_stats, type_counter


# ─────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────

@app.route("/")
def index():
    return render_template("index.html")


# ── Search by trip code (DOM) ─────────────────
@app.route("/search", methods=["GET", "POST"])
def search():
    trip   = None
    error  = None
    code   = ""
    if request.method == "POST":
        code = request.form.get("code", "").strip().upper()
        if code:
            trip = get_trip_dom(code)
            if not trip:
                error = f'No trip found with code "{code}".'
        else:
            error = "Please enter a trip code."
    return render_template("search.html", trip=trip, error=error, code=code)


# ── Filter trips ──────────────────────────────
@app.route("/filter", methods=["GET", "POST"])
def filter_trips():
    all_trips = get_all_trips_et()

    # Unique values for dropdowns
    departures  = sorted({t["departure"] for t in all_trips})
    arrivals    = sorted({t["arrival"]   for t in all_trips})
    train_types = sorted({t["type"]      for t in all_trips})

    filtered   = None
    f_dep      = request.form.get("departure",  "").strip()
    f_arr      = request.form.get("arrival",    "").strip()
    f_type     = request.form.get("train_type", "").strip()
    f_maxprice = request.form.get("max_price",  "").strip()

    if request.method == "POST":
        filtered = all_trips
        if f_dep:
            filtered = [t for t in filtered if t["departure"] == f_dep]
        if f_arr:
            filtered = [t for t in filtered if t["arrival"] == f_arr]
        if f_type:
            filtered = [t for t in filtered if t["type"] == f_type]
        if f_maxprice:
            try:
                mp = int(f_maxprice)
                filtered = [t for t in filtered if t["min_price"] <= mp]
            except ValueError:
                pass

    return render_template(
        "filter.html",
        trips=filtered,
        departures=departures,
        arrivals=arrivals,
        train_types=train_types,
        f_dep=f_dep,
        f_arr=f_arr,
        f_type=f_type,
        f_maxprice=f_maxprice,
    )


# ── Statistics ────────────────────────────────
@app.route("/stats")
def stats():
    line_stats, type_counter = get_statistics()
    return render_template("stats.html", line_stats=line_stats, type_counter=type_counter)


# ─────────────────────────────────────────────
if __name__ == "__main__":
    app.run(debug=True)
