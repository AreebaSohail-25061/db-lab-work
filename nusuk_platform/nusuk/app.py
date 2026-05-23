"""
NUSUK — Sacred Journey Management Platform
Flask Backend Application
"""

from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import mysql.connector
from mysql.connector import Error
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from datetime import datetime, date, timedelta
import os, random, uuid

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'nusuk-sacred-2025-XkQ9mP2vL')

# ─── Database Config ──────────────────────────────────────────────────────────
DB_CONFIG = {
    'host':     os.environ.get('DB_HOST',     'localhost'),
    'user':     os.environ.get('DB_USER',     'root'),
    'password': os.environ.get('DB_PASSWORD', 'root123'),
    'database': 'NUSUK_Database',
}

def get_db():
    conn = mysql.connector.connect(**DB_CONFIG)
    conn.autocommit = False
    return conn

def init_db():
    """Create extension tables and seed default admin/analyst accounts."""
    conn = get_db()
    cur  = conn.cursor()
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS user_accounts (
                account_id    INT AUTO_INCREMENT PRIMARY KEY,
                username      VARCHAR(50)  NOT NULL UNIQUE,
                email         VARCHAR(100) NOT NULL UNIQUE,
                password_hash VARCHAR(255) NOT NULL,
                role          ENUM('admin','analyst','user') NOT NULL DEFAULT 'user',
                pilgrim_id    INT,
                is_active     BOOLEAN DEFAULT TRUE,
                created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE SET NULL
            )
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS service_ratings (
                rating_id    INT AUTO_INCREMENT PRIMARY KEY,
                pilgrim_id   INT NOT NULL,
                booking_id   INT NOT NULL,
                service_type ENUM('Hotel','Transport','Guide') NOT NULL,
                service_id   INT NOT NULL,
                rating       INT NOT NULL,
                comment      VARCHAR(500),
                created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (pilgrim_id) REFERENCES pilgrims(pilgrim_id) ON DELETE CASCADE,
                FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
                CONSTRAINT ck_rating_value CHECK (rating BETWEEN 1 AND 5),
                UNIQUE KEY uk_pilgrim_booking_service (pilgrim_id, booking_id, service_type, service_id)
            )
        """)
        cur.execute("SELECT COUNT(*) FROM user_accounts WHERE role IN ('admin','analyst')")
        if cur.fetchone()[0] == 0:
            cur.execute("INSERT INTO user_accounts (username,email,password_hash,role) VALUES (%s,%s,%s,'admin')",
                        ('admin', 'admin@nusuk.sa', generate_password_hash('Admin@Nusuk2025')))
            cur.execute("INSERT INTO user_accounts (username,email,password_hash,role) VALUES (%s,%s,%s,'analyst')",
                        ('analyst', 'analyst@nusuk.sa', generate_password_hash('Analyst@Nusuk2025')))
        conn.commit()
    except Error as e:
        conn.rollback()
        print(f"DB init warning: {e}")
    finally:
        cur.close(); conn.close()

# ─── Quran Verses ─────────────────────────────────────────────────────────────
QURAN_VERSES = [
    {"arabic": "وَأَتِمُّوا الْحَجَّ وَالْعُمْرَةَ لِلَّهِ",
     "translation": "And complete the Hajj and Umrah for Allah.",
     "reference": "Surah Al-Baqarah 2:196"},
    {"arabic": "وَلِلَّهِ عَلَى النَّاسِ حِجُّ الْبَيْتِ مَنِ اسْتَطَاعَ إِلَيْهِ سَبِيلًا",
     "translation": "Pilgrimage to the House is a duty owed to Allah by all who are able.",
     "reference": "Surah Al-Imran 3:97"},
    {"arabic": "إِنَّ أَوَّلَ بَيْتٍ وُضِعَ لِلنَّاسِ لَلَّذِي بِبَكَّةَ مُبَارَكًا وَهُدًى لِّلْعَالَمِينَ",
     "translation": "The first House established for mankind was that at Makkah — blessed and a guidance for the worlds.",
     "reference": "Surah Al-Imran 3:96"},
    {"arabic": "وَأَذِّن فِي النَّاسِ بِالْحَجِّ يَأْتُوكَ رِجَالًا وَعَلَىٰ كُلِّ ضَامِرٍ",
     "translation": "And proclaim the Hajj among people: they will come to you on foot and on every lean camel.",
     "reference": "Surah Al-Hajj 22:27"},
    {"arabic": "رَبَّنَا تَقَبَّلْ مِنَّا ۖ إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ",
     "translation": "Our Lord, accept from us. Indeed, You are the Hearing, the Knowing.",
     "reference": "Surah Al-Baqarah 2:127"},
    {"arabic": "فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ ۚ وَحَيْثُ مَا كُنتُمْ فَوَلُّوا وُجُوهَكُمْ شَطْرَهُ",
     "translation": "Turn your face toward the Sacred Mosque. Wherever you are, turn your faces toward it.",
     "reference": "Surah Al-Baqarah 2:144"},
    {"arabic": "وَإِذْ جَعَلْنَا الْبَيْتَ مَثَابَةً لِّلنَّاسِ وَأَمْنًا",
     "translation": "And recall when We made the House a place of return for the people, and a sanctuary.",
     "reference": "Surah Al-Baqarah 2:125"},
]

# ─── Auth Decorators ──────────────────────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'account_id' not in session:
            flash('Please sign in to continue.', 'warning')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

def role_required(*roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if session.get('role') not in roles:
                flash('Access denied.', 'danger')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated
    return decorator

# ─── Landing & Auth ───────────────────────────────────────────────────────────
@app.route('/')
def index():
    if 'account_id' in session:
        return redirect(url_for('dashboard'))
    return render_template('index.html', verse=random.choice(QURAN_VERSES))

@app.route('/dashboard')
@login_required
def dashboard():
    role = session.get('role')
    if role == 'admin':    return redirect(url_for('admin_dashboard'))
    if role == 'analyst':  return redirect(url_for('analyst_dashboard'))
    return redirect(url_for('user_dashboard'))

@app.route('/login', methods=['GET','POST'])
def login():
    if 'account_id' in session:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        email    = request.form.get('email','').strip()
        password = request.form.get('password','').strip()
        conn = get_db(); cur = conn.cursor(dictionary=True)
        cur.execute("SELECT * FROM user_accounts WHERE email=%s AND is_active=TRUE", (email,))
        user = cur.fetchone(); cur.close(); conn.close()
        if user and check_password_hash(user['password_hash'], password):
            session.update({
                'account_id': user['account_id'],
                'username':   user['username'],
                'email':      user['email'],
                'role':       user['role'],
                'pilgrim_id': user['pilgrim_id'],
            })
            flash(f"Welcome back, {user['username']}!", 'success')
            return redirect(url_for('dashboard'))
        flash('Invalid email or password.', 'danger')
    return render_template('auth/login.html')

@app.route('/register', methods=['GET','POST'])
def register():
    if 'account_id' in session:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        f = request.form
        conn = get_db(); cur = conn.cursor(dictionary=True)
        try:
            cur.execute("SELECT account_id FROM user_accounts WHERE email=%s OR username=%s",
                        (f['email'], f['username']))
            if cur.fetchone():
                flash('Email or username already registered.', 'danger')
                raise Exception('dup')
            cur.execute("""
                INSERT INTO pilgrims
                  (first_name,last_name,gender,passport_number,nationality_id,
                   date_of_birth,email,phone_number,registration_status)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,'Active')
            """, (f['first_name'],f['last_name'],f['gender'],f['passport_number'],
                  f['nationality_id'],f['date_of_birth'],f['email'],f.get('phone_number','')))
            pid = cur.lastrowid
            cur.execute("""
                INSERT INTO user_accounts (username,email,password_hash,role,pilgrim_id)
                VALUES (%s,%s,%s,'user',%s)
            """, (f['username'],f['email'],generate_password_hash(f['password']),pid))
            conn.commit()
            flash('Account created! Please sign in.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            conn.rollback()
            if str(e) != 'dup':
                flash(f'Registration error: {e}', 'danger')
        finally:
            cur.close(); conn.close()
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("SELECT nationality_id,country_name FROM nationalities ORDER BY country_name")
    nations = cur.fetchall(); cur.close(); conn.close()
    return render_template('auth/register.html', nationalities=nations)

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been signed out.', 'info')
    return redirect(url_for('index'))

# ─── USER routes ──────────────────────────────────────────────────────────────
@app.route('/user/dashboard')
@login_required
@role_required('user')
def user_dashboard():
    pid  = session['pilgrim_id']
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT p.*,n.country_name FROM pilgrims p
                   JOIN nationalities n ON p.nationality_id=n.nationality_id
                   WHERE p.pilgrim_id=%s""", (pid,))
    pilgrim = cur.fetchone()
    cur.execute("SELECT COUNT(*) cnt FROM bookings WHERE pilgrim_id=%s AND status NOT IN ('Cancelled')", (pid,))
    active_bookings = cur.fetchone()['cnt']
    cur.execute("SELECT COUNT(*) cnt FROM permits WHERE pilgrim_id=%s AND status='Active'", (pid,))
    active_permits = cur.fetchone()['cnt']
    cur.execute("""SELECT hp.*,hph.phase_name,hph.phase_order
                   FROM hajj_progress hp JOIN hajj_phases hph ON hp.phase_id=hph.phase_id
                   WHERE hp.pilgrim_id=%s ORDER BY hph.phase_order""", (pid,))
    hajj_progress = cur.fetchall()
    cur.close(); conn.close()
    return render_template('user/dashboard.html', pilgrim=pilgrim,
                           active_bookings=active_bookings, active_permits=active_permits,
                           hajj_progress=hajj_progress, verse=random.choice(QURAN_VERSES))

@app.route('/user/profile')
@login_required
@role_required('user')
def user_profile():
    pid  = session['pilgrim_id']
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT p.*,n.country_name,n.region FROM pilgrims p
                   JOIN nationalities n ON p.nationality_id=n.nationality_id
                   WHERE p.pilgrim_id=%s""", (pid,))
    pilgrim = cur.fetchone()
    cur.execute("SELECT * FROM health_records WHERE pilgrim_id=%s", (pid,))
    health = cur.fetchall()
    cur.execute("SELECT * FROM visas WHERE pilgrim_id=%s ORDER BY issue_date DESC", (pid,))
    visas = cur.fetchall()
    cur.execute("SELECT * FROM special_needs WHERE pilgrim_id=%s", (pid,))
    needs = cur.fetchall()
    cur.close(); conn.close()
    return render_template('user/profile.html', pilgrim=pilgrim,
                           health_records=health, visas=visas, special_needs=needs)

@app.route('/user/bookings')
@login_required
@role_required('user')
def user_bookings():
    pid  = session['pilgrim_id']
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT b.*,pg.group_name FROM bookings b
                   LEFT JOIN pilgrim_groups pg ON b.group_id=pg.group_id
                   WHERE b.pilgrim_id=%s ORDER BY b.booking_date DESC""", (pid,))
    bookings = cur.fetchall()
    for bk in bookings:
        cur.execute("""SELECT bd.*,h.hotel_name,tp.company_name,g.first_name,g.last_name
                       FROM booking_details bd
                       LEFT JOIN hotels h ON bd.hotel_id=h.hotel_id
                       LEFT JOIN transport_providers tp ON bd.provider_id=tp.provider_id
                       LEFT JOIN guides g ON bd.guide_id=g.guide_id
                       WHERE bd.booking_id=%s""", (bk['booking_id'],))
        bk['details'] = cur.fetchall()
        if bk['status'] == 'Completed':
            cur.execute("""SELECT service_type,service_id FROM service_ratings
                           WHERE pilgrim_id=%s AND booking_id=%s""", (pid, bk['booking_id']))
            bk['rated'] = {(r['service_type'],r['service_id']) for r in cur.fetchall()}
        else:
            bk['rated'] = set()
    cur.execute("SELECT hotel_id,hotel_name,star_rating,location_area FROM hotels ORDER BY hotel_name")
    hotels = cur.fetchall()
    cur.execute("SELECT provider_id,company_name,service_type FROM transport_providers WHERE is_active=TRUE")
    providers = cur.fetchall()
    cur.execute("SELECT guide_id,first_name,last_name,languages,rating_average FROM guides WHERE is_active=TRUE ORDER BY rating_average DESC")
    guides = cur.fetchall()
    cur.close(); conn.close()
    return render_template('user/bookings.html', bookings=bookings,
                           hotels=hotels, providers=providers, guides=guides)

@app.route('/user/bookings/add', methods=['POST'])
@login_required
@role_required('user')
def add_booking():
    pid = session['pilgrim_id']; f = request.form
    sd, ed = f.get('start_date'), f.get('end_date')
    if not sd or not ed or sd > ed:
        flash('Invalid dates.', 'danger'); return redirect(url_for('user_bookings'))
    conn = get_db(); cur = conn.cursor(dictionary=True)
    try:
        ref = 'NSK-' + uuid.uuid4().hex[:8].upper()
        details, total = [], 0.0
        nights = (date.fromisoformat(ed) - date.fromisoformat(sd)).days or 1
        hotel_id = f.get('hotel_id') or None
        provider_id = f.get('provider_id') or None
        guide_id = f.get('guide_id') or None
        if hotel_id:
            details.append(('Hotel', hotel_id, None, None, nights, 500.00))
            total += nights * 500
        if provider_id:
            details.append(('Transport', None, provider_id, None, 1, 200.00))
            total += 200
        if guide_id:
            details.append(('Guide', None, None, guide_id, 1, 300.00))
            total += 300
        if total == 0: total = 100.00
        cur.execute("""
            INSERT INTO bookings
              (pilgrim_id,booking_reference,total_price,booking_date,start_date,end_date,status)
            VALUES (%s,%s,%s,NOW(),%s,%s,'Pending')
        """, (pid, ref, total, sd, ed))
        bid = cur.lastrowid
        for svc, h, p, g, qty, uprice in details:
            cur.execute("""INSERT INTO booking_details
                (service_type,status,booking_id,hotel_id,provider_id,guide_id,
                 start_date,end_date,quantity,unit_price)
                VALUES (%s,'Active',%s,%s,%s,%s,%s,%s,%s,%s)""",
                (svc, bid, h, p, g, sd, ed, qty, uprice))
        conn.commit()
        flash(f'Booking {ref} created successfully!', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Booking failed: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('user_bookings'))

@app.route('/user/permits')
@login_required
@role_required('user')
def user_permits():
    pid  = session['pilgrim_id']
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT pm.*,hs.site_name,hs.city,ts.start_time,ts.end_time
                   FROM permits pm
                   JOIN time_slots ts ON pm.slot_id=ts.slot_id
                   JOIN holy_sites hs ON ts.site_id=hs.site_id
                   WHERE pm.pilgrim_id=%s ORDER BY pm.issue_date DESC""", (pid,))
    permits = cur.fetchall()
    cur.execute("""SELECT ts.slot_id,ts.start_time,ts.end_time,ts.max_capacity,ts.current_occupancy,
                          hs.site_name,hs.city
                   FROM time_slots ts JOIN holy_sites hs ON ts.site_id=hs.site_id
                   WHERE ts.is_open=TRUE AND ts.current_occupancy<ts.max_capacity
                   ORDER BY ts.start_time""")
    slots = cur.fetchall()
    cur.close(); conn.close()
    return render_template('user/permits.html', permits=permits, available_slots=slots)

@app.route('/user/permits/request', methods=['POST'])
@login_required
@role_required('user')
def request_permit():
    pid     = session['pilgrim_id']
    slot_id = request.form.get('slot_id', type=int)
    ptype   = request.form.get('permit_type', 'Umrah')
    if not slot_id:
        flash('Select a time slot.', 'danger'); return redirect(url_for('user_permits'))
    conn = get_db(); cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM time_slots WHERE slot_id=%s AND is_open=TRUE FOR UPDATE", (slot_id,))
        slot = cur.fetchone()
        if not slot or slot['current_occupancy'] >= slot['max_capacity']:
            flash('Slot is full or unavailable.', 'danger'); raise Exception('slot')
        cur.execute("SELECT permit_id FROM permits WHERE pilgrim_id=%s AND slot_id=%s AND issue_date=CURDATE()", (pid, slot_id))
        if cur.fetchone():
            flash('You already have a permit for this slot today.', 'warning'); raise Exception('dup')
        expiry = date.today() + timedelta(days=7)
        cur.execute("""INSERT INTO permits (pilgrim_id,slot_id,issue_date,expiry_date,status,permit_type)
                       VALUES (%s,%s,CURDATE(),%s,'Active',%s)""", (pid, slot_id, expiry, ptype))
        cur.execute("UPDATE time_slots SET current_occupancy=current_occupancy+1 WHERE slot_id=%s", (slot_id,))
        conn.commit(); flash('Permit issued successfully!', 'success')
    except Exception as e:
        conn.rollback()
        if str(e) not in ('slot','dup'): flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('user_permits'))

@app.route('/user/rate', methods=['POST'])
@login_required
@role_required('user')
def rate_service():
    pid        = session['pilgrim_id']
    booking_id = request.form.get('booking_id', type=int)
    svc_type   = request.form.get('service_type')
    svc_id     = request.form.get('service_id', type=int)
    rating     = request.form.get('rating', type=int)
    comment    = request.form.get('comment','').strip()
    if not all([booking_id, svc_type, svc_id, rating]) or not (1 <= rating <= 5):
        flash('Invalid rating data.', 'danger'); return redirect(url_for('user_bookings'))
    conn = get_db(); cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT booking_id FROM bookings WHERE booking_id=%s AND pilgrim_id=%s AND status='Completed'",
                    (booking_id, pid))
        if not cur.fetchone():
            flash('Only completed bookings can be rated.', 'warning'); raise Exception('inv')
        cur.execute("""INSERT INTO service_ratings
                       (pilgrim_id,booking_id,service_type,service_id,rating,comment)
                       VALUES (%s,%s,%s,%s,%s,%s)
                       ON DUPLICATE KEY UPDATE rating=%s,comment=%s""",
                    (pid, booking_id, svc_type, svc_id, rating, comment, rating, comment))
        if svc_type == 'Guide':
            cur.execute("""UPDATE guides SET
                rating_average=(SELECT AVG(r.rating) FROM service_ratings r WHERE r.service_type='Guide' AND r.service_id=%s)
                WHERE guide_id=%s""", (svc_id, svc_id))
        conn.commit(); flash('Thank you for your rating!', 'success')
    except Exception as e:
        conn.rollback()
        if str(e) != 'inv': flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('user_bookings'))

# ─── ADMIN routes ─────────────────────────────────────────────────────────────
@app.route('/admin/dashboard')
@login_required
@role_required('admin')
def admin_dashboard():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    stats = {}
    for key, q in [
        ('pilgrims',  "SELECT COUNT(*) cnt FROM pilgrims"),
        ('bookings',  "SELECT COUNT(*) cnt FROM bookings WHERE status NOT IN ('Cancelled')"),
        ('permits',   "SELECT COUNT(*) cnt FROM permits WHERE status='Active'"),
        ('guides',    "SELECT COUNT(*) cnt FROM guides WHERE is_active=TRUE"),
        ('groups',    "SELECT COUNT(*) cnt FROM pilgrim_groups WHERE is_active=TRUE"),
        ('users',     "SELECT COUNT(*) cnt FROM user_accounts"),
    ]:
        cur.execute(q); stats[key] = cur.fetchone()['cnt']
    cur.execute("SELECT COALESCE(SUM(amount),0) total FROM payments WHERE status='Completed'")
    stats['revenue'] = float(cur.fetchone()['total'])
    cur.execute("""SELECT b.booking_id,b.booking_reference,b.status,b.total_price,b.booking_date,
                          p.first_name,p.last_name FROM bookings b JOIN pilgrims p ON b.pilgrim_id=p.pilgrim_id
                   ORDER BY b.booking_date DESC LIMIT 10""")
    recent_bookings = cur.fetchall()
    cur.execute("""SELECT ua.account_id,ua.username,ua.email,ua.role,ua.is_active,ua.created_at
                   FROM user_accounts ua ORDER BY ua.created_at DESC LIMIT 8""")
    recent_users = cur.fetchall()
    cur.close(); conn.close()
    return render_template('admin/dashboard.html', stats=stats,
                           recent_bookings=recent_bookings, recent_users=recent_users)

@app.route('/admin/users')
@login_required
@role_required('admin')
def admin_users():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT ua.*,p.first_name,p.last_name,p.passport_number,p.registration_status
                   FROM user_accounts ua LEFT JOIN pilgrims p ON ua.pilgrim_id=p.pilgrim_id
                   ORDER BY ua.created_at DESC""")
    users = cur.fetchall(); cur.close(); conn.close()
    return render_template('admin/users.html', users=users)

@app.route('/admin/users/edit/<int:uid>', methods=['POST'])
@login_required
@role_required('admin')
def admin_edit_user(uid):
    action = request.form.get('action')
    conn = get_db(); cur = conn.cursor(dictionary=True)
    try:
        if action == 'toggle_active':
            cur.execute("UPDATE user_accounts SET is_active=NOT is_active WHERE account_id=%s", (uid,))
        elif action == 'change_role' and request.form.get('role') in ('admin','analyst','user'):
            cur.execute("UPDATE user_accounts SET role=%s WHERE account_id=%s", (request.form['role'], uid))
        elif action == 'update_pilgrim_status':
            st = request.form.get('registration_status')
            cur.execute("SELECT pilgrim_id FROM user_accounts WHERE account_id=%s", (uid,))
            row = cur.fetchone()
            if row and row['pilgrim_id']:
                cur.execute("UPDATE pilgrims SET registration_status=%s WHERE pilgrim_id=%s", (st, row['pilgrim_id']))
        conn.commit(); flash('User updated.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_users'))

@app.route('/admin/users/delete/<int:uid>', methods=['POST'])
@login_required
@role_required('admin')
def admin_delete_user(uid):
    if uid == session['account_id']:
        flash('Cannot delete your own account.', 'danger')
        return redirect(url_for('admin_users'))
    conn = get_db(); cur = conn.cursor()
    try:
        cur.execute("DELETE FROM user_accounts WHERE account_id=%s", (uid,))
        conn.commit(); flash('User deleted.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_users'))

@app.route('/admin/guides')
@login_required
@role_required('admin')
def admin_guides():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT g.*,n.country_name FROM guides g
                   JOIN nationalities n ON g.nationality_id=n.nationality_id
                   ORDER BY g.rating_average DESC""")
    guides = cur.fetchall()
    cur.execute("SELECT nationality_id,country_name FROM nationalities ORDER BY country_name")
    nations = cur.fetchall(); cur.close(); conn.close()
    return render_template('admin/guides.html', guides=guides, nationalities=nations)

@app.route('/admin/guides/add', methods=['POST'])
@login_required
@role_required('admin')
def admin_add_guide():
    f = request.form; conn = get_db(); cur = conn.cursor()
    try:
        cur.execute("""INSERT INTO guides
            (first_name,last_name,gender,nationality_id,license_number,phone_number,email,languages,is_active)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,TRUE)""",
            (f['first_name'],f['last_name'],f['gender'],f['nationality_id'],
             f['license_number'],f['phone_number'],f['email'],f['languages']))
        conn.commit(); flash('Guide added.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_guides'))

@app.route('/admin/guides/toggle/<int:gid>', methods=['POST'])
@login_required
@role_required('admin')
def admin_toggle_guide(gid):
    conn = get_db(); cur = conn.cursor()
    cur.execute("UPDATE guides SET is_active=NOT is_active WHERE guide_id=%s", (gid,))
    conn.commit(); cur.close(); conn.close()
    return redirect(url_for('admin_guides'))

@app.route('/admin/sites')
@login_required
@role_required('admin')
def admin_sites():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT hs.*,COUNT(ts.slot_id) total_slots,
                          COALESCE(SUM(ts.current_occupancy),0) total_occ
                   FROM holy_sites hs LEFT JOIN time_slots ts ON hs.site_id=ts.site_id
                   GROUP BY hs.site_id ORDER BY hs.city,hs.site_name""")
    sites = cur.fetchall(); cur.close(); conn.close()
    return render_template('admin/sites.html', sites=sites)

@app.route('/admin/sites/add', methods=['POST'])
@login_required
@role_required('admin')
def admin_add_site():
    f = request.form; conn = get_db(); cur = conn.cursor()
    try:
        cur.execute("""INSERT INTO holy_sites (site_name,city,description,prayer_times_applicable)
                       VALUES (%s,%s,%s,%s)""",
                    (f['site_name'],f['city'],f.get('description',''),1 if f.get('prayer_times') else 0))
        conn.commit(); flash('Holy site added.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_sites'))

@app.route('/admin/bookings')
@login_required
@role_required('admin')
def admin_bookings():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""SELECT b.*,p.first_name,p.last_name,p.email
                   FROM bookings b JOIN pilgrims p ON b.pilgrim_id=p.pilgrim_id
                   ORDER BY b.booking_date DESC""")
    bookings = cur.fetchall(); cur.close(); conn.close()
    return render_template('admin/bookings.html', bookings=bookings)

@app.route('/admin/bookings/status/<int:bid>', methods=['POST'])
@login_required
@role_required('admin')
def admin_update_booking(bid):
    st = request.form.get('status')
    valid = ['Pending','Confirmed','Paid','In Progress','Completed','Cancelled']
    if st not in valid:
        flash('Invalid status.', 'danger'); return redirect(url_for('admin_bookings'))
    conn = get_db(); cur = conn.cursor()
    cur.execute("UPDATE bookings SET status=%s WHERE booking_id=%s", (st, bid))
    conn.commit(); cur.close(); conn.close()
    flash('Booking status updated.', 'success')
    return redirect(url_for('admin_bookings'))
@app.route('/admin/permits')
@login_required
@role_required('admin')
def admin_permits():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT pm.*, 
               p.first_name, p.last_name, p.passport_number,
               hs.site_name, hs.city,
               ts.start_time, ts.end_time
        FROM permits pm
        JOIN pilgrims p   ON pm.pilgrim_id = p.pilgrim_id
        JOIN time_slots ts ON pm.slot_id   = ts.slot_id
        JOIN holy_sites hs ON ts.site_id   = hs.site_id
        ORDER BY pm.issue_date DESC
    """)
    permits = cur.fetchall()
    cur.close(); conn.close()
    return render_template('admin/permits.html', permits=permits)

@app.route('/admin/hajj/assign', methods=['POST'])
@login_required
@role_required('admin')
def admin_assign_hajj():
    pilgrim_id = request.form.get('pilgrim_id', type=int)
    conn = get_db(); cur = conn.cursor(dictionary=True)
    try:
        # Check phases not already assigned
        cur.execute("""
            SELECT phase_id FROM hajj_phases
            WHERE phase_id NOT IN (
                SELECT phase_id FROM hajj_progress WHERE pilgrim_id = %s
            )
            ORDER BY phase_order
        """, (pilgrim_id,))
        phases = cur.fetchall()

        if not phases:
            flash('Phases already assigned to this pilgrim.', 'warning')
        else:
            for ph in phases:
                cur.execute("""
                    INSERT INTO hajj_progress (pilgrim_id, phase_id, status)
                    VALUES (%s, %s, 'Scheduled')
                """, (pilgrim_id, ph['phase_id']))
            conn.commit()
            flash('All 5 Hajj phases assigned successfully.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_users'))


@app.route('/admin/hajj/update', methods=['POST'])
@login_required
@role_required('admin')
def admin_update_hajj():
    progress_id = request.form.get('progress_id', type=int)
    status      = request.form.get('status')
    if status not in ('Scheduled', 'In_Progress', 'Completed', 'Skipped'):
        flash('Invalid status.', 'danger')
        return redirect(url_for('admin_hajj'))
    conn = get_db(); cur = conn.cursor()
    try:
        if status == 'In_Progress':
            cur.execute("UPDATE hajj_progress SET status=%s, started_at=NOW() WHERE progress_id=%s",
                        (status, progress_id))
        elif status == 'Completed':
            cur.execute("UPDATE hajj_progress SET status=%s, completed_at=NOW() WHERE progress_id=%s",
                        (status, progress_id))
        else:
            cur.execute("UPDATE hajj_progress SET status=%s WHERE progress_id=%s",
                        (status, progress_id))
        conn.commit(); flash('Phase updated.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_hajj'))


@app.route('/admin/hajj')
@login_required
@role_required('admin')
def admin_hajj():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT hp.progress_id, hp.status, hp.started_at, hp.completed_at,
               p.first_name, p.last_name, p.pilgrim_id,
               hph.phase_name, hph.phase_order
        FROM hajj_progress hp
        JOIN pilgrims p     ON hp.pilgrim_id = p.pilgrim_id
        JOIN hajj_phases hph ON hp.phase_id  = hph.phase_id
        ORDER BY p.last_name, hph.phase_order
    """)
    progress = cur.fetchall()
    cur.close(); conn.close()
    return render_template('admin/hajj.html', progress=progress)

@app.route('/admin/permits/update/<int:permit_id>', methods=['POST'])
@login_required
@role_required('admin')
def admin_update_permit(permit_id):
    status = request.form.get('status')
    if status not in ('Active','Used','Expired','Cancelled'):
        flash('Invalid status.', 'danger')
        return redirect(url_for('admin_permits'))
    conn = get_db(); cur = conn.cursor()
    try:
        cur.execute("UPDATE permits SET status=%s WHERE permit_id=%s", (status, permit_id))
        conn.commit(); flash('Permit updated.', 'success')
    except Exception as e:
        conn.rollback(); flash(f'Error: {e}', 'danger')
    finally:
        cur.close(); conn.close()
    return redirect(url_for('admin_permits'))

# ─── ANALYST routes ───────────────────────────────────────────────────────────
@app.route('/analyst/dashboard')
@login_required
@role_required('analyst')
def analyst_dashboard():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    stats = {}
    for k, q in [
        ('pilgrims', "SELECT COUNT(*) cnt FROM pilgrims"),
        ('bookings', "SELECT COUNT(*) cnt FROM bookings"),
        ('permits',  "SELECT COUNT(*) cnt FROM permits"),
        ('guides',   "SELECT COUNT(*) cnt FROM guides WHERE is_active=TRUE"),
    ]:
        cur.execute(q); stats[k] = cur.fetchone()['cnt']
    cur.execute("SELECT COALESCE(SUM(amount),0) total FROM payments WHERE status='Completed'")
    stats['revenue'] = float(cur.fetchone()['total'])
    cur.execute("""SELECT method,COUNT(*) transactions,COALESCE(SUM(amount),0) total
                   FROM payments WHERE status='Completed' GROUP BY method ORDER BY total DESC""")
    revenue_by_method = cur.fetchall()
    cur.execute("SELECT status,COUNT(*) cnt FROM bookings GROUP BY status ORDER BY cnt DESC")
    bookings_by_status = cur.fetchall()
    cur.execute("""SELECT g.first_name,g.last_name,g.rating_average,g.total_pilgrim_count
                   FROM guides g WHERE g.is_active=TRUE ORDER BY g.rating_average DESC LIMIT 5""")
    top_guides = cur.fetchall()
    cur.execute("""SELECT n.country_name,n.region,COUNT(p.pilgrim_id) cnt
                   FROM nationalities n LEFT JOIN pilgrims p ON n.nationality_id=p.nationality_id
                   GROUP BY n.nationality_id HAVING cnt>0 ORDER BY cnt DESC LIMIT 10""")
    nationality_stats = cur.fetchall()
    cur.execute("""SELECT hs.site_name,hs.city,COUNT(ts.slot_id) total_slots,
                          ROUND(COALESCE(AVG(ts.current_occupancy/ts.max_capacity*100),0),1) avg_occ
                   FROM holy_sites hs LEFT JOIN time_slots ts ON hs.site_id=ts.site_id
                   GROUP BY hs.site_id ORDER BY avg_occ DESC""")
    site_occupancy = cur.fetchall()
    cur.execute("""SELECT permit_type,status,COUNT(*) cnt FROM permits
                   GROUP BY permit_type,status ORDER BY permit_type,status""")
    permit_stats = cur.fetchall()
    cur.execute("""SELECT h.hotel_name,h.star_rating,h.location_area,COUNT(bd.detail_id) cnt
                   FROM hotels h LEFT JOIN booking_details bd ON h.hotel_id=bd.hotel_id AND bd.status='Active'
                   GROUP BY h.hotel_id ORDER BY cnt DESC""")
    hotel_stats = cur.fetchall()
    cur.execute("SELECT registration_status,COUNT(*) cnt FROM pilgrims GROUP BY registration_status")
    pilgrim_status = cur.fetchall()
    cur.execute("""SELECT method,COUNT(*) cnt FROM payments GROUP BY method ORDER BY cnt DESC""")
    payment_methods = cur.fetchall()
    cur.close(); conn.close()
    return render_template('analyst/dashboard.html',
                           stats=stats, revenue_by_method=revenue_by_method,
                           bookings_by_status=bookings_by_status, top_guides=top_guides,
                           nationality_stats=nationality_stats, site_occupancy=site_occupancy,
                           permit_stats=permit_stats, hotel_stats=hotel_stats,
                           pilgrim_status=pilgrim_status, payment_methods=payment_methods)

# ─── API ──────────────────────────────────────────────────────────────────────
@app.route('/api/verse')
def api_verse():
    return jsonify(random.choice(QURAN_VERSES))

@app.route('/api/slot-availability')
@login_required
def api_slots():
    conn = get_db(); cur = conn.cursor(dictionary=True)
    cur.execute("SELECT COUNT(*) cnt FROM time_slots WHERE is_open=TRUE AND current_occupancy<max_capacity")
    n = cur.fetchone()['cnt']; cur.close(); conn.close()
    return jsonify({'open_slots': n})

# ─── Run ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    with app.app_context():
        try: init_db(); print("✓ DB ready")
        except Exception as e: print(f"✗ DB init: {e}")
    app.run(debug=True, host='0.0.0.0', port=5000)
