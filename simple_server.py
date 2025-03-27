import http.server
import socketserver
import os
import json
import urllib.parse
from http import HTTPStatus, cookies
try:
    from dotenv import load_dotenv
    # Load environment variables from .env file
    load_dotenv()
except ImportError:
    print("python-dotenv not installed, using environment variables directly")

class GalleryzeHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Check if requesting login or signup page
        if self.path == '/login':
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_login_page().encode())
        elif self.path == '/signup':
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_signup_page().encode())
        # Check if user is logged in (has valid session cookie)
        elif self.path == '/supabase_client.js':
            # Read Supabase client JS and inject environment variables
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/javascript')
            self.end_headers()
            
            # Inject Supabase credentials from environment variables
            supabase_vars = f"""
// Supabase environment variables
window.SUPABASE_URL = '{os.environ.get('SUPABASE_URL')}';
window.SUPABASE_KEY = '{os.environ.get('SUPABASE_KEY')}';
"""
            # Write the environment variables first, then the content of the file
            self.wfile.write(supabase_vars.encode())
            
            with open('supabase_client.js', 'rb') as file:
                self.wfile.write(file.read())
        elif self.is_authenticated() or self.path == '/new_galleryze_script.js':
            # Serve app content for authenticated users
            if self.path == '/' or self.path == '/home':
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(self.get_home_page("all").encode())
            elif self.path == '/favorites':
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(self.get_home_page("favorites").encode())
            elif self.path == '/categories':
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(self.get_categories_page().encode())
            elif self.path == '/new_galleryze_script.js':
                # Serve our JavaScript file
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'application/javascript')
                self.end_headers()
                with open('new_galleryze_script.js', 'rb') as file:
                    self.wfile.write(file.read())
            elif self.path.startswith('/filter/'):
                # Handle filtering by category
                category = self.path.split('/')[2]
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(self.get_home_page(category).encode())
            elif self.path == '/settings':
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(self.get_settings_page().encode())
            elif self.path == '/profile':
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(self.get_profile_page().encode())
            elif self.path == '/api/user':
                # Get current user info
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"user": self.get_user_info()}).encode())
            elif self.path == '/api/favorites':
                # Get user's favorites
                if not self.is_authenticated():
                    self.send_response(HTTPStatus.UNAUTHORIZED)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": False, "message": "Not authenticated"}).encode())
                    return
                
                # Here we would fetch from Supabase, but for now return dummy data
                user_info = self.get_user_info()
                self.send_response(HTTPStatus.OK)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                # Mock favorites for photo2 and photo5
                self.wfile.write(json.dumps({
                    "success": True, 
                    "favorites": [
                        {"user_id": user_info["id"], "photo_id": "photo2", "is_favorite": True},
                        {"user_id": user_info["id"], "photo_id": "photo5", "is_favorite": True}
                    ]
                }).encode())
            else:
                self.send_error(HTTPStatus.NOT_FOUND, "Page not found")
        else:
            # Redirect unauthenticated users to login page
            self.send_response(HTTPStatus.FOUND)
            self.send_header('Location', '/login')
            self.end_headers()
    
    def do_POST(self):
        # Handle API endpoints
        if self.path == '/api/login':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Process login request
            email = data.get('email')
            user_id = data.get('userId')
            supabase_token = data.get('supabaseToken')
            
            # Verify that we have user ID and token from Supabase
            if not user_id or not supabase_token:
                self.send_response(HTTPStatus.BAD_REQUEST)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": False, 
                    "message": "Missing user credentials"
                }).encode())
                return
                
            # In a production app, we would verify the token with Supabase
            # For this demo, we'll trust the token and set a session
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/json')
            
            # Store user ID and token in session cookie
            session_data = f"{user_id}:{supabase_token}"
            self.send_header('Set-Cookie', f'session={session_data}; Path=/')
            
            self.end_headers()
            self.wfile.write(json.dumps({
                "success": True, 
                "message": "Logged in successfully"
            }).encode())
        elif self.path == '/api/signup':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Process signup request
            name = data.get('name')
            email = data.get('email')
            user_id = data.get('userId')
            
            # Verify we have necessary data
            if not name or not email or not user_id:
                self.send_response(HTTPStatus.BAD_REQUEST)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": False, 
                    "message": "Missing required signup information"
                }).encode())
                return
            
            # Set default subscription to 'free'
            subscription_plan = 'free'
            
            # In a production app, we would store user metadata (name, subscription_plan) in Supabase
            # Also create entries in the profiles table or similar
            
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "success": True, 
                "message": "Signed up successfully", 
                "user": {
                    "id": user_id,
                    "name": name,
                    "email": email,
                    "subscription_plan": subscription_plan
                }
            }).encode())
        elif self.path == '/api/logout':
            # Process logout request
            cookie = cookies.SimpleCookie()
            cookie['session'] = ""
            cookie['session']['path'] = '/'
            cookie['session']['expires'] = 'Thu, 01 Jan 1970 00:00:00 GMT'  # Expire the cookie
            
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/json')
            self.send_header('Set-Cookie', cookie['session'].OutputString())
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "message": "Logged out successfully"}).encode())
        elif self.path == '/api/categories':
            # Only process if user is authenticated
            if not self.is_authenticated():
                self.send_response(HTTPStatus.UNAUTHORIZED)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "message": "Not authenticated"}).encode())
                return
                
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Save category data
            photo_id = data.get('photoId')
            categories = data.get('categories')
            
            # Here we would save to Supabase database
            # For now, just return a success message
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "message": "Categories saved successfully"}).encode())
        elif self.path == '/api/favorites':
            # Only process if user is authenticated
            if not self.is_authenticated():
                self.send_response(HTTPStatus.UNAUTHORIZED)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "message": "Not authenticated"}).encode())
                return
                
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Get favorite data
            photo_id = data.get('photoId')
            is_favorite = data.get('isFavorite')
            
            # Here we would save to Supabase database
            # For now, just return a success message
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "message": "Favorite status saved successfully"}).encode())
        elif self.path == '/api/categories/create':
            # Only process if user is authenticated
            if not self.is_authenticated():
                self.send_response(HTTPStatus.UNAUTHORIZED)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "message": "Not authenticated"}).encode())
                return
                
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Get category data
            category_name = data.get('categoryName')
            
            # Validate the category name
            if not category_name or len(category_name.strip()) == 0:
                self.send_response(HTTPStatus.BAD_REQUEST)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "message": "Category name cannot be empty"}).encode())
                return
            
            # Here we would save to Supabase database
            # For now, just return a success message
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "success": True, 
                "message": "Category created successfully", 
                "category": {
                    "name": category_name, 
                    "id": str(hash(category_name) % 10000)  # Simple hash for demo purposes
                }
            }).encode())
        # No else here, as we've already handled all of our API endpoints
        else:
            self.send_error(HTTPStatus.NOT_FOUND, "Endpoint not found")
    
    def is_authenticated(self):
        # Check if the user has a valid session cookie
        cookie_str = self.headers.get('Cookie')
        if cookie_str:
            cookie = cookies.SimpleCookie()
            cookie.load(cookie_str)
            if 'session' in cookie and cookie['session'].value:
                # In a production app, we would verify the Supabase token here
                # For now, just check that we have a non-empty session
                return len(cookie['session'].value) > 0
        return False
    
    def get_user_info(self):
        # Get session cookie
        cookie_str = self.headers.get('Cookie')
        if cookie_str:
            cookie = cookies.SimpleCookie()
            cookie.load(cookie_str)
            if 'session' in cookie and cookie['session'].value:
                # Session cookie is in format userId:token
                parts = cookie['session'].value.split(':')
                if len(parts) >= 1:
                    # Get user ID from parts
                    user_id = parts[0]
                    
                    # For a real app, we would fetch this from Supabase
                    # For demonstration purposes, we'll use the same user ID to return consistent user info
                    # This ensures consistent user details across different parts of the app
                    return {
                        "id": user_id,
                        "email": f"{user_id[:6]}@galleryze.app",
                        "name": f"User {user_id[:6]}",
                        "subscription_plan": "free"
                    }
        
        # Fallback to default user data
        return {
            "id": "guest",
            "email": "guest@example.com",
            "name": "Guest User",
            "subscription_plan": "free"
        }
    
    def get_home_page(self, filter_type="all"):
        # Set which chip should be selected based on filter
        all_selected = "selected" if filter_type == "all" else ""
        favorites_selected = "selected" if filter_type == "favorites" else ""
        
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Home</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {self.get_styles()}
            </style>
            <script src="/new_galleryze_script.js"></script>
        </head>
        <body>
            <nav class="top-nav">
                <h1>Galleryze</h1>
                <div class="nav-actions">
                    <div class="sort-menu">
                        <button class="icon-btn small sort-btn" onclick="toggleSortOptions()" title="Sort photos">
                            <svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="#666">
                                <path d="M0 0h24v24H0z" fill="none"/>
                                <path d="M3 18h6v-2H3v2zM3 6v2h18V6H3zm0 7h12v-2H3v2z"/>
                            </svg>
                        </button>
                        <div id="sort-options" class="sort-options">
                            <div class="sort-option" onclick="sortPhotos('date', 'desc')">Date (Newest first)</div>
                            <div class="sort-option" onclick="sortPhotos('date', 'asc')">Date (Oldest first)</div>
                            <div class="sort-option" onclick="sortPhotos('size', 'desc')">Size (Largest first)</div>
                            <div class="sort-option" onclick="sortPhotos('size', 'asc')">Size (Smallest first)</div>
                        </div>
                    </div>
                    <button class="pro-btn">PRO</button>
                </div>
            </nav>
            
            <div class="category-filter">
                <span class="chip ${all_selected}" onclick="navigateToFilter('all')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z"/>
                    </svg>
                    All Photos
                </span>
                <span class="chip ${favorites_selected}" onclick="navigateToFilter('favorites')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                    </svg>
                    Favorites
                </span>
                <span class="chip" onclick="navigateToFilter('Recent')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M13 3a9 9 0 00-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42A8.954 8.954 0 0013 21a9 9 0 000-18zm-1 5v5l4.28 2.54.72-1.21-3.5-2.08V8H12z"/>
                    </svg>
                    Recent
                </span>
                <span class="chip" onclick="navigateToFilter('Vacation')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M13.127 14.56l1.43-1.43 6.44 6.443L19.57 21l-6.44-6.44zM17.42 8.83l2.86-2.86c-3.95-3.95-10.35-3.96-14.3-.02 3.93-1.3 8.31-.25 11.44 2.88zM5.95 5.98c-3.94 3.95-3.93 10.35.02 14.3l2.86-2.86C5.7 14.29 4.65 9.91 5.95 5.98zM5.97 5.96l-.01.01c-.38 3.01 1.17 6.88 4.3 10.02l5.73-5.73c-3.13-3.13-7.01-4.68-10.02-4.3z"/>
                    </svg>
                    Vacation
                </span>
                <span class="chip" onclick="navigateToFilter('Family')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M16 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63A2.01 2.01 0 0018.06 7h-.12a2 2 0 00-1.9 1.37l-.02.06L12.5 18h1v6h6.5zm-2.5-22a3.5 3.5 0 100 7 3.5 3.5 0 000-7zM10 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63A2.01 2.01 0 0012.06 7h-.12a2 2 0 00-1.9 1.37l-.02.06L6.5 18h1v6h6.5zM3.5 12c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 8v-5h8v5H18v-6.5l-1.8-5.5c-.13-.39-.44-.71-.82-.87-.38-.17-.81-.16-1.19.01l-.46.18c-.19.07-.34.21-.42.39L10 16.5V22H7.5z"/>
                    </svg>
                    Family
                </span>
                <span class="chip" onclick="navigateToFilter('Food')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z"/>
                    </svg>
                    Food
                </span>
                <span class="chip" onclick="navigateToFilter('Nature')">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M8.55 12c-1.07-.71-2.25-1.27-3.53-1.61 1.28.34 2.46.9 3.53 1.61zm10.43-1.61c-1.29.34-2.49.91-3.57 1.64 1.08-.73 2.28-1.3 3.57-1.64zm-3.49-.76c-.18-2.79-1.31-5.51-3.43-7.63-2.14 2.14-3.32 4.86-3.55 7.63 1.28.68 2.46 1.56 3.49 2.63 1.03-1.06 2.21-1.94 3.49-2.63zm-6.5 2.65c-.14-.1-.3-.19-.45-.29.15.11.31.19.45.29zm6.42-.25c-.13.09-.27.16-.4.26.13-.1.27-.17.4-.26zM12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z"/>
                    </svg>
                    Nature
                </span>
                <span class="chip add-chip" onclick="openCreateCategoryModal()">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 5px;">
                        <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
                    </svg>
                    Add
                </span>
            </div>
            <div class="current-filter" data-filter="${filter_type}" style="display:none;"></div>
            
            <div class="photo-grid" id="photo-grid">
                <div class="photo-item" data-favorite="false" data-id="photo1" data-categories="" data-date="2023-06-15" data-size="1200">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">1</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo1')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo1')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo2" data-categories="" data-date="2023-09-10" data-size="2400">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">2</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo2')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo2')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo3" data-date="2022-12-05" data-size="800" data-categories="">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">3</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo3')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo3')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo4" data-date="2023-07-22" data-size="1500" data-categories="">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">4</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo4')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo4')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo5" data-date="2023-01-14" data-size="900" data-categories="">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">5</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo5')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo5')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo6" data-date="2023-03-30" data-size="2100" data-categories="">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">6</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo6')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo6')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo7" data-date="2022-10-09" data-size="1050" data-categories="">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">7</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo7')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo7')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
                <div class="photo-item" data-favorite="false" data-id="photo8" data-date="2023-08-05" data-size="3000" data-categories="">
                    <div class="photo-placeholder">
                        <span style="position: absolute; top: 42%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; color: #333;">8</span>
                    </div>
                    <div class="category-btn" onclick="openCategoryModal('photo8')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 5h-3v3h3v3h-3v3h-2v-3H9v-3h3V8H9V6h3V3h2v3h3v2z"/></svg></div>
                    <div class="favorite-btn" onclick="toggleFavorite(this, 'photo8')"><svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24" fill="white"><path d="M0 0h24v24H0z" fill="none"/><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg></div>
                </div>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item active" title="Home">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
                </a>
                <a href="/categories" class="nav-item" title="Categories">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 2l-5.5 9h11z"/><circle cx="17.5" cy="17.5" r="4.5"/><path d="M3 13.5h8v8H3z"/></svg>
                </a>
                <a href="/settings" class="nav-item" title="Settings">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
                </a>
            </div>
            
            <!-- Category Modal -->
            <div class="modal" id="categoryModal">
                <div class="modal-content">
                    <div class="modal-header">
                        <h2 class="modal-title">Photo Categories</h2>
                        <button class="modal-close" onclick="closeCategoryModal()">&times;</button>
                    </div>
                    <div id="currentPhotoId" style="display: none;"></div>
                    <div class="category-option">
                        <input type="checkbox" id="category-Recent" class="category-checkbox" data-category="Recent">
                        <label for="category-Recent">Recent</label>
                    </div>
                    <div class="category-option">
                        <input type="checkbox" id="category-Vacation" class="category-checkbox" data-category="Vacation">
                        <label for="category-Vacation">Vacation</label>
                    </div>
                    <div class="category-option">
                        <input type="checkbox" id="category-Family" class="category-checkbox" data-category="Family">
                        <label for="category-Family">Family</label>
                    </div>
                    <div class="category-option">
                        <input type="checkbox" id="category-Food" class="category-checkbox" data-category="Food">
                        <label for="category-Food">Food</label>
                    </div>
                    <div class="category-option">
                        <input type="checkbox" id="category-Nature" class="category-checkbox" data-category="Nature">
                        <label for="category-Nature">Nature</label>
                    </div>
                    <button class="action-btn" onclick="saveCategories()">Save Categories</button>
                </div>
            </div>
            
            <!-- Photo Details Modal -->
            <div class="modal" id="photoDetailsModal">
                <div class="modal-content">
                    <div class="modal-header">
                        <h2 class="modal-title">Photo Details</h2>
                        <button class="modal-close" onclick="closePhotoDetailsModal()">&times;</button>
                    </div>
                    <div class="photo-details-content">
                        <div class="photo-details-preview">
                            <div class="photo-placeholder" id="photoDetailsPreview"></div>
                        </div>
                        <div class="photo-details-info">
                            <div class="photo-detail-item">
                                <strong>ID:</strong> <span id="photoDetailsId"></span>
                            </div>
                            <div class="photo-detail-item">
                                <strong>Date:</strong> <span id="photoDetailsDate"></span>
                            </div>
                            <div class="photo-detail-item">
                                <strong>Size:</strong> <span id="photoDetailsSize"></span> KB
                            </div>
                            <div class="photo-detail-item">
                                <strong>Categories:</strong> <span id="photoDetailsCategories"></span>
                            </div>
                            <div class="photo-detail-item">
                                <strong>Favorite:</strong> <span id="photoDetailsFavorite"></span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Create Category Modal -->
            <div class="modal" id="createCategoryModal">
                <div class="modal-content">
                    <div class="modal-header">
                        <h2 class="modal-title">Create New Category</h2>
                        <button class="modal-close" onclick="closeCreateCategoryModal()">&times;</button>
                    </div>
                    <div class="form-group">
                        <label for="newCategoryName">Category Name</label>
                        <input type="text" id="newCategoryName" placeholder="Enter category name..." required>
                    </div>
                    <button class="action-btn" onclick="createNewCategory()">Create Category</button>
                </div>
            </div>
        </body>
        </html>
        """
    
    def get_categories_page(self):
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Categories</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {self.get_styles()}
            </style>
            <script src="/new_galleryze_script.js"></script>
        </head>
        <body>
            <nav class="top-nav">
                <h1>Categories</h1>
            </nav>
            
            <div class="content">
                <p class="subheader">Manage your photo categories</p>
                
                <div class="category-list">
                    <div class="category-item">
                        <div class="category-icon blue">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M22 16V4c0-1.1-.9-2-2-2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2zm-11-4l2.03 2.71L16 11l4 5H8l3-4zM2 6v14c0 1.1.9 2 2 2h14v-2H4V6H2z"/>
                            </svg>
                        </div>
                        <div class="category-name">All Photos</div>
                        <div class="category-badge">Default</div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon red">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                            </svg>
                        </div>
                        <div class="category-name">Favorites</div>
                        <div class="category-badge">Default</div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon purple">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/>
                                <path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z"/>
                            </svg>
                        </div>
                        <div class="category-name">Recent</div>
                        <div class="category-badge">Default</div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon orange">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M13.127 14.56l1.43-1.43 6.44 6.443L19.57 21l-6.44-6.44zM17.42 8.83l2.86-2.86c-3.95-3.95-10.35-3.96-14.3-.02 3.93-1.3 8.31-.25 11.44 2.88zM5.95 5.98c-3.94 3.95-3.93 10.35.02 14.3l2.86-2.86C5.7 14.29 4.65 9.91 5.95 5.98zM5.97 5.96l-.01.01c-.38 3.01 1.17 6.88 4.3 10.02l5.73-5.73c-3.13-3.13-7.01-4.68-10.02-4.3z"/>
                            </svg>
                        </div>
                        <div class="category-name">Vacation</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon green">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M16 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63A2.01 2.01 0 0018.06 7h-.12a2 2 0 00-1.9 1.37l-.02.06L12.5 18h1v6h6.5zm-2.5-22a3.5 3.5 0 100 7 3.5 3.5 0 000-7zM10 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63A2.01 2.01 0 0012.06 7h-.12a2 2 0 00-1.9 1.37l-.02.06L6.5 18h1v6h6.5zM3.5 12c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 8v-5h8v5H18v-6.5l-1.8-5.5c-.13-.39-.44-.71-.82-.87-.38-.17-.81-.16-1.19.01l-.46.18c-.19.07-.34.21-.42.39L10 16.5V22H7.5z"/>
                            </svg>
                        </div>
                        <div class="category-name">Family</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon amber">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z"/>
                            </svg>
                        </div>
                        <div class="category-name">Food</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon green">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
                                <path d="M8.55 12c-1.07-.71-2.25-1.27-3.53-1.61 1.28.34 2.46.9 3.53 1.61zm10.43-1.61c-1.29.34-2.49.91-3.57 1.64 1.08-.73 2.28-1.3 3.57-1.64zm-3.49-.76c-.18-2.79-1.31-5.51-3.43-7.63-2.14 2.14-3.32 4.86-3.55 7.63 1.28.68 2.46 1.56 3.49 2.63 1.03-1.06 2.21-1.94 3.49-2.63zm-6.5 2.65c-.14-.1-.3-.19-.45-.29.15.11.31.19.45.29zm6.42-.25c-.13.09-.27.16-.4.26.13-.1.27-.17.4-.26zM12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z"/>
                            </svg>
                        </div>
                        <div class="category-name">Nature</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                </div>
                
                <button class="fab" onclick="openCreateCategoryModal()">+</button>
            </div>
            
            <!-- Create Category Modal -->
            <div class="modal" id="createCategoryModal">
                <div class="modal-content">
                    <div class="modal-header">
                        <h2 class="modal-title">Create New Category</h2>
                        <button class="modal-close" onclick="closeCreateCategoryModal()">&times;</button>
                    </div>
                    <div class="form-group">
                        <label for="newCategoryName">Category Name</label>
                        <input type="text" id="newCategoryName" placeholder="Enter category name..." required>
                    </div>
                    <button class="action-btn" onclick="createNewCategory()">Create Category</button>
                </div>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item" title="Home">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
                </a>
                <a href="/categories" class="nav-item active" title="Categories">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 2l-5.5 9h11z"/><circle cx="17.5" cy="17.5" r="4.5"/><path d="M3 13.5h8v8H3z"/></svg>
                </a>
                <a href="/settings" class="nav-item" title="Settings">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
                </a>
            </div>
        </body>
        </html>
        """
    
    def get_login_page(self):
        styles = self.get_styles()
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Login</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {styles}
                
                body {{
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    margin: 0;
                    padding: 0;
                    height: 100vh;
                    background: linear-gradient(45deg, #f8f9fa, #ffefd5);
                    display: flex;
                    flex-direction: column;
                    justify-content: space-between;
                    align-items: center;
                }}
                
                .logo-container {{
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    margin-top: 60px;
                }}
                
                .app-logo {{
                    width: 80px;
                    height: 80px;
                    border-radius: 20px;
                    background-color: #222;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    overflow: hidden;
                    margin-bottom: 15px;
                }}
                
                .app-logo img {{
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }}
                
                .app-name {{
                    font-size: 24px;
                    font-weight: 600;
                    color: #333;
                    margin: 0;
                }}
                
                .auth-container {{
                    width: 90%;
                    max-width: 400px;
                    display: flex;
                    flex-direction: column;
                    gap: 20px;
                }}
                
                .form-group {{
                    position: relative;
                }}
                
                .form-group input {{
                    width: 100%;
                    padding: 16px;
                    border: 1px solid #e0e0e0;
                    border-radius: 8px;
                    font-size: 16px;
                    background-color: #fff;
                    box-sizing: border-box;
                }}
                
                .form-group input::placeholder {{
                    color: #aaa;
                }}
                
                .primary-btn {{
                    width: 100%;
                    padding: 16px;
                    background: #222;
                    color: white;
                    border: none;
                    border-radius: 50px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: background 0.2s;
                    margin-top: 10px;
                }}
                
                .primary-btn:hover {{
                    background: #333;
                }}
                
                .secondary-btn {{
                    width: 100%;
                    padding: 16px;
                    background: transparent;
                    color: #333;
                    border: 1px solid #ddd;
                    border-radius: 50px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.2s;
                    margin-top: 10px;
                }}
                
                .secondary-btn:hover {{
                    background: #f5f5f5;
                }}
                
                .footer {{
                    text-align: center;
                    margin-bottom: 20px;
                    color: #666;
                    font-size: 14px;
                }}
                
                .footer a {{
                    color: #333;
                    text-decoration: none;
                    font-weight: 600;
                }}
            </style>
            <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
            <script src="/supabase_client.js"></script>
            <script>
                async function handleLogin(event) {{
                    event.preventDefault();
                    
                    const email = document.getElementById('email').value;
                    const password = document.getElementById('password').value;
                    
                    try {{
                        // Use Supabase authentication
                        const {{ data, error }} = await galleryzeApi.signIn(email, password);
                        
                        if (error) {{
                            throw error;
                        }}
                        
                        if (data && data.user) {{
                            // Successfully signed in with Supabase, now create a server session
                            const response = await fetch('/api/login', {{
                                method: 'POST',
                                headers: {{
                                    'Content-Type': 'application/json'
                                }},
                                body: JSON.stringify({{ 
                                    email, 
                                    userId: data.user.id,
                                    supabaseToken: data.session.access_token 
                                }})
                            }});
                            
                            const result = await response.json();
                            
                            if (result.success) {{
                                window.location.href = '/';
                            }} else {{
                                alert(result.message || 'Failed to login');
                            }}
                        }} else {{
                            alert('Login failed. Please check your credentials.');
                        }}
                    }} catch (error) {{
                        console.error('Login error:', error);
                        alert(error.message || 'Login failed. Please try again.');
                    }}
                }}
            </script>
        </head>
        <body>
            <div class="logo-container">
                <div class="app-logo">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="60" height="60">
                        <path d="M70 40 L90 65 L50 90 L10 65 L30 40 Z" fill="#555" />
                        <circle cx="70" cy="30" r="15" fill="#ff7043" />
                    </svg>
                </div>
                <h1 class="app-name">Galleryze</h1>
            </div>
            
            <div class="auth-container">
                <form id="loginForm" onsubmit="handleLogin(event)">
                    <div class="form-group">
                        <input type="email" id="email" placeholder="Username, email or mobile number" required>
                    </div>
                    <div class="form-group">
                        <input type="password" id="password" placeholder="Password" required>
                    </div>
                    <button type="submit" class="primary-btn">Log in</button>
                </form>
                <a href="/signup" class="secondary-btn" style="display: block; text-align: center; text-decoration: none;">Create new account</a>
            </div>
            
            <div class="footer">
                Developed by <a href="#">pAssist</a>
            </div>
        </body>
        </html>
        """
    
    def get_signup_page(self):
        styles = self.get_styles()
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Sign Up</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {styles}
                
                body {{
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    margin: 0;
                    padding: 0;
                    height: 100vh;
                    background: linear-gradient(45deg, #f8f9fa, #ffefd5);
                    display: flex;
                    flex-direction: column;
                    justify-content: space-between;
                    align-items: center;
                }}
                
                .logo-container {{
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    margin-top: 60px;
                }}
                
                .app-logo {{
                    width: 80px;
                    height: 80px;
                    border-radius: 20px;
                    background-color: #222;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    overflow: hidden;
                    margin-bottom: 15px;
                }}
                
                .app-logo img {{
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }}
                
                .app-name {{
                    font-size: 24px;
                    font-weight: 600;
                    color: #333;
                    margin: 0;
                }}
                
                .auth-container {{
                    width: 90%;
                    max-width: 400px;
                    display: flex;
                    flex-direction: column;
                    gap: 20px;
                }}
                
                .form-group {{
                    position: relative;
                    margin-bottom: 15px;
                }}
                
                .form-group input {{
                    width: 100%;
                    padding: 16px;
                    border: 1px solid #e0e0e0;
                    border-radius: 8px;
                    font-size: 16px;
                    background-color: #fff;
                    box-sizing: border-box;
                }}
                
                .form-group input::placeholder {{
                    color: #aaa;
                }}
                
                .primary-btn {{
                    width: 100%;
                    padding: 16px;
                    background: #222;
                    color: white;
                    border: none;
                    border-radius: 50px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: background 0.2s;
                    margin-top: 10px;
                }}
                
                .primary-btn:hover {{
                    background: #333;
                }}
                
                .secondary-btn {{
                    width: 100%;
                    padding: 16px;
                    background: transparent;
                    color: #333;
                    border: 1px solid #ddd;
                    border-radius: 50px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.2s;
                    margin-top: 10px;
                }}
                
                .secondary-btn:hover {{
                    background: #f5f5f5;
                }}
                
                .footer {{
                    text-align: center;
                    margin-bottom: 20px;
                    color: #666;
                    font-size: 14px;
                }}
                
                .footer a {{
                    color: #333;
                    text-decoration: none;
                    font-weight: 600;
                }}
            </style>
            <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
            <script src="/supabase_client.js"></script>
            <script>
                async function handleSignup(event) {{
                    event.preventDefault();
                    
                    const name = document.getElementById('name').value;
                    const email = document.getElementById('email').value;
                    const password = document.getElementById('password').value;
                    const confirmPassword = document.getElementById('confirmPassword').value;
                    
                    if (password !== confirmPassword) {{
                        alert('Passwords do not match');
                        return;
                    }}
                    
                    try {{
                        // Register with Supabase Authentication
                        const {{ data, error }} = await galleryzeApi.signUp(email, password);
                        
                        if (error) {{
                            throw error;
                        }}
                        
                        if (data && data.user) {{
                            // After successful signup, store additional user metadata (name, subscription plan)
                            const response = await fetch('/api/signup', {{
                                method: 'POST',
                                headers: {{
                                    'Content-Type': 'application/json'
                                }},
                                body: JSON.stringify({{ 
                                    name, 
                                    email, 
                                    userId: data.user.id 
                                }})
                            }});
                            
                            const result = await response.json();
                            
                            if (result.success) {{
                                alert('Account created successfully! Please check your email to confirm your account, then log in.');
                                window.location.href = '/login';
                            }} else {{
                                alert(result.message || 'Account created but failed to save profile data.');
                            }}
                        }} else {{
                            alert('Failed to create account. Please try again.');
                        }}
                    }} catch (error) {{
                        console.error('Signup error:', error);
                        alert(error.message || 'Signup failed. Please try again.');
                    }}
                }}
            </script>
        </head>
        <body>
            <div class="logo-container">
                <div class="app-logo">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="60" height="60">
                        <path d="M70 40 L90 65 L50 90 L10 65 L30 40 Z" fill="#555" />
                        <circle cx="70" cy="30" r="15" fill="#ff7043" />
                    </svg>
                </div>
                <h1 class="app-name">Galleryze</h1>
            </div>
            
            <div class="auth-container">
                <form id="signupForm" onsubmit="handleSignup(event)">
                    <div class="form-group">
                        <input type="text" id="name" placeholder="Full Name" required>
                    </div>
                    <div class="form-group">
                        <input type="email" id="email" placeholder="Email" required>
                    </div>
                    <div class="form-group">
                        <input type="password" id="password" placeholder="Password" required minlength="6">
                    </div>
                    <div class="form-group">
                        <input type="password" id="confirmPassword" placeholder="Confirm Password" required minlength="6">
                    </div>
                    <button type="submit" class="primary-btn">Sign Up</button>
                </form>
                <a href="/login" class="secondary-btn" style="display: block; text-align: center; text-decoration: none;">Back to Login</a>
            </div>
            
            <div class="footer">
                Developed by <a href="#">pAssist</a>
            </div>
        </body>
        </html>
        """
    
    def get_profile_page(self):
        user_info = self.get_user_info()
        styles = self.get_styles()
        name = user_info['name']
        email = user_info['email']
        first_initial = name[0].upper()
        
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Profile</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {styles}
                
                .profile-container {{
                    max-width: 600px;
                    margin: 20px auto;
                    padding: 20px;
                    background: #fff;
                    border-radius: 8px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }}
                
                .profile-header {{
                    display: flex;
                    align-items: center;
                    margin-bottom: 20px;
                }}
                
                .profile-avatar {{
                    width: 80px;
                    height: 80px;
                    border-radius: 50%;
                    background: #e0e0e0;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 32px;
                    color: #666;
                    margin-right: 20px;
                }}
                
                .profile-info h2 {{
                    margin: 0 0 5px 0;
                }}
                
                .profile-email {{
                    color: #666;
                    margin: 0;
                }}
                
                .profile-stats {{
                    display: flex;
                    margin: 20px 0;
                    border-top: 1px solid #eee;
                    border-bottom: 1px solid #eee;
                    padding: 15px 0;
                }}
                
                .stat-item {{
                    flex: 1;
                    text-align: center;
                }}
                
                .stat-value {{
                    font-size: 24px;
                    font-weight: bold;
                    margin-bottom: 5px;
                }}
                
                .stat-label {{
                    color: #666;
                    font-size: 14px;
                }}
                
                .action-button {{
                    padding: 10px 15px;
                    background: #f5f5f5;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    margin-right: 10px;
                }}
                
                .logout-button {{
                    padding: 10px 15px;
                    background: #ff4d4f;
                    color: white;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                }}
            </style>
            <script src="/new_galleryze_script.js"></script>
            <script>
                async function handleLogout() {{
                    try {{
                        // First sign out from Supabase
                        const {{ error }} = await galleryzeApi.signOut();
                        if (error) {{
                            console.error('Supabase logout error:', error);
                        }}
                        
                        // Then clear session on server
                        const response = await fetch('/api/logout', {{
                            method: 'POST',
                            headers: {{
                                'Content-Type': 'application/json'
                            }}
                        }});
                        
                        const result = await response.json();
                        
                        if (result.success) {{
                            console.log('Logged out successfully');
                            window.location.href = '/login';
                        }} else {{
                            alert(result.message || 'Failed to logout');
                        }}
                    }} catch (error) {{
                        console.error('Logout error:', error);
                        alert('Logout failed. Please try again.');
                    }}
                }}
            </script>
        </head>
        <body>
            <nav class="top-nav">
                <h1>Galleryze</h1>
            </nav>
            
            <div class="profile-container">
                <div class="profile-header">
                    <div class="profile-avatar">{first_initial}</div>
                    <div class="profile-info">
                        <h2>{name}</h2>
                        <p class="profile-email">{email}</p>
                    </div>
                </div>
                
                <div class="profile-stats">
                    <div class="stat-item">
                        <div class="stat-value">128</div>
                        <div class="stat-label">Photos</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value">5</div>
                        <div class="stat-label">Categories</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value">24</div>
                        <div class="stat-label">Favorites</div>
                    </div>
                </div>
                
                <div>
                    <button class="action-button">Edit Profile</button>
                    <button class="action-button">Change Password</button>
                    <button class="logout-button" onclick="handleLogout()">Log Out</button>
                </div>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item" title="Home">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
                </a>
                <a href="/categories" class="nav-item" title="Categories">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 2l-5.5 9h11z"/><circle cx="17.5" cy="17.5" r="4.5"/><path d="M3 13.5h8v8H3z"/></svg>
                </a>
                <a href="/settings" class="nav-item active" title="Settings">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
                </a>
            </div>
        </body>
        </html>
        """
        
    def get_settings_page(self):
        user_info = self.get_user_info()
        name = user_info['name']
        email = user_info['email']
        subscription_plan = user_info['subscription_plan']
        
        # Capitalize first letter of subscription plan for display
        display_subscription = subscription_plan.capitalize()
        
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Settings</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {self.get_styles()}
                
                .user-profile-section {{
                    background: #fff;
                    border-radius: 8px;
                    padding: 20px;
                    margin-bottom: 20px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }}
                
                .user-profile-header {{
                    display: flex;
                    align-items: center;
                    margin-bottom: 15px;
                }}
                
                .user-avatar {{
                    width: 60px;
                    height: 60px;
                    border-radius: 50%;
                    background: #e0e0e0;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 24px;
                    color: #666;
                    margin-right: 15px;
                }}
                
                .user-details h3 {{
                    margin: 0 0 5px 0;
                }}
                
                .user-email {{
                    color: #666;
                    margin: 0;
                }}
                
                .subscription-badge {{
                    display: inline-block;
                    background: #f0f0f0;
                    padding: 4px 8px;
                    border-radius: 4px;
                    font-size: 14px;
                    margin-top: 8px;
                }}
                
                .subscription-badge.free {{
                    background: #e8f5e9;
                    color: #2e7d32;
                }}
                
                .subscription-badge.pro {{
                    background: #e3f2fd;
                    color: #1565c0;
                }}
            </style>
            <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
            <script src="/supabase_client.js"></script>
            <script src="/new_galleryze_script.js"></script>
        </head>
        <body>
            <nav class="top-nav">
                <h1>Settings</h1>
            </nav>
            
            <div class="content">
                <div class="user-profile-section">
                    <div class="user-profile-header">
                        <div class="user-avatar">{name[0].upper()}</div>
                        <div class="user-details">
                            <h3>{name}</h3>
                            <p class="user-email">{email}</p>
                            <span class="subscription-badge {subscription_plan}">{display_subscription} Plan</span>
                        </div>
                    </div>
                    <button class="btn-secondary">Edit Profile</button>
                    <button class="btn-danger" onclick="handleLogout()">Sign Out</button>
                </div>
                <script>
                    async function handleLogout() {{
                        try {{
                            // First sign out from Supabase
                            const {{ error }} = await galleryzeApi.signOut();
                            if (error) {{
                                console.error('Supabase logout error:', error);
                            }}
                            
                            // Then clear session on server
                            const response = await fetch('/api/logout', {{
                                method: 'POST',
                                headers: {{
                                    'Content-Type': 'application/json'
                                }}
                            }});
                            
                            const result = await response.json();
                            if (result.success) {{
                                console.log('Logged out successfully');
                                window.location.href = '/login';
                            }} else {{
                                alert(result.message || 'Failed to sign out');
                            }}
                        }} catch (error) {{
                            console.error('Logout error:', error);
                            alert('Failed to sign out. Please try again.');
                        }}
                    }}
                </script>
                
                <p class="subheader">App Settings</p>
                
                <div class="settings-section">
                    <div class="section-header">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M12 22C6.49 22 2 17.51 2 12S6.49 2 12 2s10 4.04 10 9c0 3.31-2.69 6-6 6h-1.77c-.28 0-.5.22-.5.5 0 .12.05.23.13.33.41.47.64 1.06.64 1.67A2.5 2.5 0 0 1 12 22zm0-18c-4.41 0-8 3.59-8 8s3.59 8 8 8c.28 0 .5-.22.5-.5a.54.54 0 0 0-.14-.35c-.41-.46-.63-1.05-.63-1.65a2.5 2.5 0 0 1 2.5-2.5H16c2.21 0 4-1.79 4-4 0-3.86-3.59-7-8-7z"/>
                            <circle cx="6.5" cy="11.5" r="1.5" fill="#2196f3"/>
                            <circle cx="9.5" cy="7.5" r="1.5" fill="#2196f3"/>
                            <circle cx="14.5" cy="7.5" r="1.5" fill="#2196f3"/>
                            <circle cx="17.5" cy="11.5" r="1.5" fill="#2196f3"/>
                        </svg>
                        <h2>Appearance</h2>
                    </div>
                    <hr>
                    <div class="setting-item">
                        <div class="setting-info">
                            <h3>Dark Mode</h3>
                            <p>Enable dark mode</p>
                        </div>
                        <div class="setting-control">
                            <label class="switch">
                                <input type="checkbox">
                                <span class="slider round"></span>
                            </label>
                        </div>
                    </div>
                    <div class="setting-item">
                        <div class="setting-info">
                            <h3>Grid Size</h3>
                            <p>Adjust photo grid density</p>
                        </div>
                        <div class="setting-control">
                            <select>
                                <option>Small</option>
                                <option selected>Medium</option>
                                <option>Large</option>
                            </select>
                        </div>
                    </div>
                </div>
                
                <div class="settings-section">
                    <div class="section-header">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M2 20h20v-4H2v4zm2-3h2v2H4v-2zM2 4v4h20V4H2zm4 3H4V5h2v2zm-4 7h20v-4H2v4zm2-3h2v2H4v-2z"/>
                        </svg>
                        <h2>Storage</h2>
                    </div>
                    <hr>
                    <div class="setting-item">
                        <div class="setting-info">
                            <h3>Cache Size</h3>
                            <p>Manage app cache</p>
                        </div>
                        <div class="setting-control">
                            <button class="btn-secondary">Clear Cache</button>
                        </div>
                    </div>
                </div>
                
                <div class="settings-section">
                    <div class="section-header">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
                        </svg>
                        <h2>Privacy</h2>
                    </div>
                    <hr>
                    <div class="setting-item">
                        <div class="setting-info">
                            <h3>App Lock</h3>
                            <p>Secure your photos with a PIN</p>
                        </div>
                        <div class="setting-control">
                            <label class="switch">
                                <input type="checkbox">
                                <span class="slider round"></span>
                            </label>
                        </div>
                    </div>
                </div>
                
                <div class="settings-section">
                    <div class="section-header">
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="#2196f3">
                            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/>
                        </svg>
                        <h2>About</h2>
                    </div>
                    <hr>
                    <div class="setting-item">
                        <div class="setting-info">
                            <h3>Version</h3>
                            <p>Current app version</p>
                        </div>
                        <div class="setting-control">
                            <span class="version">v1.0.0</span>
                        </div>
                    </div>
                    <div class="setting-item">
                        <div class="setting-info">
                            <h3>Feedback</h3>
                            <p>Send feedback to developers</p>
                        </div>
                        <div class="setting-control">
                            <button class="btn-secondary">Send</button>
                        </div>
                    </div>
                </div>
                
                <div class="pro-card">
                    <div class="pro-header">
                        <div class="pro-avatar">PRO</div>
                        <div class="pro-info">
                            <h2>Upgrade to PRO</h2>
                            <p>Get unlimited categories, cloud sync and more</p>
                        </div>
                    </div>
                    <button class="btn-primary full-width">Upgrade Now</button>
                </div>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item" title="Home">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
                </a>
                <a href="/categories" class="nav-item" title="Categories">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 2l-5.5 9h11z"/><circle cx="17.5" cy="17.5" r="4.5"/><path d="M3 13.5h8v8H3z"/></svg>
                </a>
                <a href="/settings" class="nav-item active" title="Settings">
                    <svg xmlns="http://www.w3.org/2000/svg" height="28" viewBox="0 0 24 24" width="28" fill="currentColor"><path d="M0 0h24v24H0z" fill="none"/><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
                </a>
            </div>
        </body>
        </html>
        """
    
    def get_styles(self):
        return """
            * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
            body { background-color: #f5f5f5; color: #333; display: flex; flex-direction: column; min-height: 100vh; }
            
            /* Typography */
            h1 { font-size: 24px; }
            h2 { font-size: 18px; }
            h3 { font-size: 16px; }
            p { font-size: 14px; color: #666; }
            
            /* Navigation */
            .top-nav { display: flex; justify-content: space-between; align-items: center; padding: 16px; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .nav-actions { display: flex; align-items: center; }
            
            /* Sort Menu */
            .sort-menu { position: relative; }
            .sort-options { display: none; position: absolute; top: 40px; right: 0; background-color: white; border-radius: 4px; box-shadow: 0 2px 8px rgba(0,0,0,0.2); width: 200px; z-index: 100; }
            .sort-option { padding: 12px 16px; cursor: pointer; }
            .sort-option:hover { background-color: #f5f5f5; }
            
            .bottom-nav { display: flex; justify-content: space-around; background-color: rgba(255, 255, 255, 0.8); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); box-shadow: 0 -2px 8px rgba(0,0,0,0.07); padding: 8px 0; position: fixed; bottom: 0; left: 0; width: 100%; z-index: 100; border-top: 1px solid rgba(255, 255, 255, 0.3); }
            .nav-item { display: flex; justify-content: center; align-items: center; color: #999; text-decoration: none; padding: 10px; }
            .nav-item.active { color: #2196f3; }
            .nav-item svg { margin: 0; }
            
            /* Buttons */
            button { cursor: pointer; border: none; outline: none; }
            .pro-btn { background-color: #2196f3; color: white; border-radius: 20px; padding: 4px 12px; font-weight: bold; margin-left: 8px; }
            .icon-btn { background-color: transparent; display: flex; justify-content: center; align-items: center; width: 40px; height: 40px; border-radius: 50%; }
            .icon-btn.small { width: 32px; height: 32px; }
            .icon-btn:hover { background-color: rgba(0,0,0,0.05); }
            .fab { position: fixed; bottom: 80px; right: 20px; width: 56px; height: 56px; border-radius: 50%; background-color: #2196f3; color: white; font-size: 24px; display: flex; justify-content: center; align-items: center; box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
            .btn-secondary { background-color: #f0f0f0; color: #333; border-radius: 4px; padding: 8px 16px; margin-right: 10px; }
            .btn-danger { background-color: #f44336; color: white; border-radius: 4px; padding: 8px 16px; }
            
            /* Material Icons stand-in */
            i { font-style: normal; }
            
            /* Category Filter */
            .category-filter { display: flex; overflow-x: auto; padding: 16px; gap: 8px; background-color: white; }
            .chip { background-color: #f0f0f0; border-radius: 20px; padding: 10px 18px; font-size: 16px; white-space: nowrap; margin-right: 12px; cursor: pointer; display: inline-block; min-width: 100px; text-align: center; font-weight: 500; }
            .chip.selected { background-color: #2196f3; color: white; }
            .chip:hover { background-color: #e0e0e0; transition: background-color 0.2s; }
            
            /* Photo Grid */
            .photo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; padding: 16px; flex-grow: 1; padding-bottom: 70px; }
            .photo-item { aspect-ratio: 1/1; position: relative; cursor: pointer; }
            .photo-placeholder { 
                background-color: #f0f0f0; 
                width: 100%; 
                height: 100%; 
                display: flex; 
                justify-content: center; 
                align-items: center; 
                color: #777; 
                border-radius: 8px; 
                overflow: hidden; 
                font-size: 14px; 
                background-image: linear-gradient(120deg, #e0f2f1 0%, #b2dfdb 50%, #80cbc4 100%);
                box-shadow: inset 0 0 15px rgba(0,0,0,0.1);
                position: relative;
            }
            
            .photo-placeholder::before {
                content: '';
                position: absolute;
                width: 60%;
                height: 60%;
                background-color: rgba(255,255,255,0.7);
                border-radius: 4px;
                background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' height='24' viewBox='0 0 24 24' width='24' fill='%23999'%3E%3Cpath d='M0 0h24v24H0z' fill='none'/%3E%3Cpath d='M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z'/%3E%3C/svg%3E");
                background-repeat: no-repeat;
                background-position: center;
                background-size: 32px;
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            }
            .favorite-btn { position: absolute; top: 8px; right: 8px; width: 32px; height: 32px; border-radius: 50%; background-color: rgba(0, 0, 0, 0.3); display: flex; justify-content: center; align-items: center; cursor: pointer; transition: all 0.2s; z-index: 2; }
            .favorite-btn i { color: white; font-size: 18px; }
            .favorite-btn.active i { color: #f44336; }
            .favorite-btn:hover { background-color: rgba(0, 0, 0, 0.5); }
            .category-btn { position: absolute; top: 8px; left: 8px; width: 32px; height: 32px; border-radius: 50%; background-color: rgba(0, 0, 0, 0.3); display: flex; justify-content: center; align-items: center; cursor: pointer; transition: all 0.2s; z-index: 2; }
            .category-btn i { color: white; font-size: 18px; }
            .category-btn:hover { background-color: rgba(0, 0, 0, 0.5); }
            
            /* Modal */
            .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.7); z-index: 10; align-items: center; justify-content: center; }
            .modal-content { background-color: white; border-radius: 8px; width: 90%; max-width: 400px; max-height: 80%; overflow-y: auto; padding: 20px; }
            .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
            .modal-title { font-size: 18px; font-weight: 600; }
            .modal-close { background: none; border: none; font-size: 24px; cursor: pointer; }
            .category-option { display: flex; align-items: center; padding: 12px; border-bottom: 1px solid #eee; }
            .category-option:last-child { border-bottom: none; }
            .category-checkbox { margin-right: 10px; }
            .action-btn { background-color: #2196f3; color: white; border: none; border-radius: 4px; padding: 10px 15px; cursor: pointer; font-weight: 500; width: 100%; margin-top: 15px; }
            
            /* Photo Details Modal */
            .photo-details-content { display: flex; flex-direction: column; }
            .photo-details-preview { margin-bottom: 20px; }
            .photo-details-preview .photo-placeholder { 
                height: 200px; 
                width: 100%; 
                background-image: linear-gradient(135deg, #f5f7fa 0%, #e4e8ed 100%);
            }
            .photo-details-preview .photo-placeholder::before {
                width: 40%;
                height: 40%;
            }
            .photo-details-info { display: flex; flex-direction: column; gap: 10px; }
            .photo-detail-item { padding: 8px 0; border-bottom: 1px solid #eee; }
            .photo-detail-item:last-child { border-bottom: none; }
            
            /* Content Area */
            .content { padding: 16px; margin-bottom: 80px; }
            .subheader { margin-bottom: 16px; }
            
            /* Category List */
            .category-list { display: flex; flex-direction: column; gap: 16px; }
            .category-item { display: flex; align-items: center; background-color: white; padding: 16px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
            .category-icon { width: 40px; height: 40px; border-radius: 50%; display: flex; justify-content: center; align-items: center; color: white; margin-right: 16px; }
            .category-icon i, .category-icon svg { color: white; }
            .blue { background-color: #2196f3; }
            .red { background-color: #f44336; }
            .purple { background-color: #9c27b0; }
            .green { background-color: #4caf50; }
            .orange { background-color: #ff9800; }
            .amber { background-color: #ffc107; }
            .category-name { flex-grow: 1; font-weight: bold; }
            .category-badge { background-color: #999; color: white; font-size: 12px; padding: 2px 8px; border-radius: 12px; }
            .category-actions { display: flex; }
            
            /* Settings */
            .settings-section { background-color: white; border-radius: 8px; margin-bottom: 16px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
            .section-header { display: flex; align-items: center; margin-bottom: 8px; }
            .section-header i, .section-header svg { margin-right: 8px; color: #2196f3; }
            hr { border: none; border-top: 1px solid #eee; margin: 8px 0 16px; }
            .setting-item { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
            .setting-item:last-child { margin-bottom: 0; }
            .setting-info { flex-grow: 1; }
            .setting-control { margin-left: 16px; }
            
            /* Switch */
            .switch { position: relative; display: inline-block; width: 48px; height: 24px; }
            .switch input { opacity: 0; width: 0; height: 0; }
            .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #ccc; transition: .4s; border-radius: 24px; }
            .slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s; border-radius: 50%; }
            input:checked + .slider { background-color: #2196f3; }
            input:checked + .slider:before { transform: translateX(24px); }
            
            /* Form Controls */
            select { padding: 8px; border: 1px solid #ddd; border-radius: 4px; background-color: white; }
            .btn-secondary { background-color: #f5f5f5; color: #333; padding: 8px 12px; border-radius: 4px; }
            .version { color: #999; font-weight: bold; }
            
            /* PRO Card */
            .pro-card { background-color: #e3f2fd; border-radius: 8px; padding: 16px; margin-top: 24px; }
            .pro-header { display: flex; margin-bottom: 16px; }
            .pro-avatar { width: 48px; height: 48px; border-radius: 50%; background-color: #bbdefb; color: #2196f3; display: flex; justify-content: center; align-items: center; font-weight: bold; margin-right: 16px; }
            .btn-primary { background-color: #2196f3; color: white; padding: 12px; border-radius: 4px; font-weight: bold; }
            .full-width { width: 100%; }
        """

# Set up the server
PORT = 5000
Handler = GalleryzeHandler

with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Server running at http://0.0.0.0:{PORT}")
    httpd.serve_forever()