import http.server
import socketserver
import os
from http import HTTPStatus

class GalleryzeHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_home_page().encode())
        elif self.path == '/categories':
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_categories_page().encode())
        elif self.path == '/settings':
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_settings_page().encode())
        elif self.path == '/share':
            self.send_response(HTTPStatus.OK)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_share_page().encode())
        else:
            self.send_error(HTTPStatus.NOT_FOUND, "Page not found")
    
    def get_home_page(self):
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
        </head>
        <body>
            <nav class="top-nav">
                <h1>Galleryze</h1>
                <div class="nav-actions">
                    <button class="icon-btn"><i>sort</i></button>
                    <button class="pro-btn">PRO</button>
                </div>
            </nav>
            
            <div class="category-filter">
                <span class="chip selected">All Photos</span>
                <span class="chip">Favorites</span>
                <span class="chip">Recent</span>
                <span class="chip">Vacation</span>
                <span class="chip">Family</span>
                <span class="chip">Food</span>
                <span class="chip">+ Add</span>
            </div>
            
            <div class="photo-grid">
                <div class="photo-item"><div class="photo-placeholder">Photo 1</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 2</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 3</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 4</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 5</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 6</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 7</div></div>
                <div class="photo-item"><div class="photo-placeholder">Photo 8</div></div>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item active">
                    <i>home</i>
                    <span>Home</span>
                </a>
                <a href="/categories" class="nav-item">
                    <i>category</i>
                    <span>Categories</span>
                </a>
                <a href="/settings" class="nav-item">
                    <i>settings</i>
                    <span>Settings</span>
                </a>
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
                            <i>photo_library</i>
                        </div>
                        <div class="category-name">All Photos</div>
                        <div class="category-badge">Default</div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon red">
                            <i>favorite</i>
                        </div>
                        <div class="category-name">Favorites</div>
                        <div class="category-badge">Default</div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon purple">
                            <i>access_time</i>
                        </div>
                        <div class="category-name">Recent</div>
                        <div class="category-badge">Default</div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon orange">
                            <i>beach_access</i>
                        </div>
                        <div class="category-name">Vacation</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon green">
                            <i>family_restroom</i>
                        </div>
                        <div class="category-name">Family</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                    
                    <div class="category-item">
                        <div class="category-icon amber">
                            <i>restaurant</i>
                        </div>
                        <div class="category-name">Food</div>
                        <div class="category-actions">
                            <button class="icon-btn small"><i>edit</i></button>
                            <button class="icon-btn small"><i>delete</i></button>
                        </div>
                    </div>
                </div>
                
                <button class="fab">+</button>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item">
                    <i>home</i>
                    <span>Home</span>
                </a>
                <a href="/categories" class="nav-item active">
                    <i>category</i>
                    <span>Categories</span>
                </a>
                <a href="/settings" class="nav-item">
                    <i>settings</i>
                    <span>Settings</span>
                </a>
            </div>
        </body>
        </html>
        """
    
    def get_settings_page(self):
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Settings</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {self.get_styles()}
            </style>
        </head>
        <body>
            <nav class="top-nav">
                <h1>Settings</h1>
            </nav>
            
            <div class="content">
                <p class="subheader">App Settings</p>
                
                <div class="settings-section">
                    <div class="section-header">
                        <i>color_lens</i>
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
                        <i>storage</i>
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
                        <i>lock</i>
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
                        <i>info</i>
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
                <a href="/" class="nav-item">
                    <i>home</i>
                    <span>Home</span>
                </a>
                <a href="/categories" class="nav-item">
                    <i>category</i>
                    <span>Categories</span>
                </a>
                <a href="/settings" class="nav-item active">
                    <i>settings</i>
                    <span>Settings</span>
                </a>
            </div>
        </body>
        </html>
        """
    
    def get_share_page(self):
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Galleryze - Share</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                {self.get_styles()}
            </style>
        </head>
        <body>
            <nav class="top-nav">
                <h1>Share Category</h1>
                <div class="nav-actions">
                    <button class="icon-btn" onclick="window.history.back()"><i>arrow_back</i></button>
                </div>
            </nav>
            
            <div class="content">
                <p class="subheader">Share your photo collections with friends</p>
                
                <div class="share-preview">
                    <div class="category-icon orange large">
                        <i>beach_access</i>
                    </div>
                    <h2 class="share-title">Vacation Collection</h2>
                    <p class="share-count">24 photos</p>
                    <div class="share-thumbnail-grid">
                        <div class="share-thumbnail"><div class="photo-placeholder">Photo</div></div>
                        <div class="share-thumbnail"><div class="photo-placeholder">Photo</div></div>
                        <div class="share-thumbnail"><div class="photo-placeholder">Photo</div></div>
                        <div class="share-thumbnail"><div class="photo-placeholder">Photo</div></div>
                    </div>
                </div>
                
                <div class="share-options">
                    <h3>Share with one tap</h3>
                    
                    <div class="social-buttons">
                        <button class="social-btn facebook">
                            <i>facebook</i>
                            <span>Facebook</span>
                        </button>
                        <button class="social-btn twitter">
                            <i>twitter</i>
                            <span>Twitter</span>
                        </button>
                        <button class="social-btn instagram">
                            <i>instagram</i>
                            <span>Instagram</span>
                        </button>
                        <button class="social-btn whatsapp">
                            <i>whatsapp</i>
                            <span>WhatsApp</span>
                        </button>
                    </div>
                    
                    <div class="share-link-container">
                        <input type="text" class="share-link" value="https://galleryze.app/share/vacation-123" readonly>
                        <button class="btn-secondary">Copy</button>
                    </div>
                    
                    <div class="share-settings">
                        <div class="setting-item">
                            <div class="setting-info">
                                <h3>Public Access</h3>
                                <p>Allow anyone with the link to view</p>
                            </div>
                            <div class="setting-control">
                                <label class="switch">
                                    <input type="checkbox" checked>
                                    <span class="slider round"></span>
                                </label>
                            </div>
                        </div>
                        <div class="setting-item">
                            <div class="setting-info">
                                <h3>Password Protection</h3>
                                <p>Require a password to access</p>
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
                                <h3>Expiration</h3>
                                <p>Set an expiration date for this share</p>
                            </div>
                            <div class="setting-control">
                                <select>
                                    <option>Never</option>
                                    <option>1 day</option>
                                    <option>7 days</option>
                                    <option>30 days</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="bottom-nav">
                <a href="/" class="nav-item">
                    <i>home</i>
                    <span>Home</span>
                </a>
                <a href="/categories" class="nav-item">
                    <i>category</i>
                    <span>Categories</span>
                </a>
                <a href="/settings" class="nav-item">
                    <i>settings</i>
                    <span>Settings</span>
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
            
            .bottom-nav { display: flex; justify-content: space-around; background-color: white; box-shadow: 0 -2px 4px rgba(0,0,0,0.1); padding: 8px 0; position: fixed; bottom: 0; width: 100%; }
            .nav-item { display: flex; flex-direction: column; align-items: center; color: #999; text-decoration: none; padding: 8px 16px; }
            .nav-item.active { color: #2196f3; }
            .nav-item i { margin-bottom: 4px; }
            
            /* Buttons */
            button { cursor: pointer; border: none; outline: none; }
            .pro-btn { background-color: #2196f3; color: white; border-radius: 20px; padding: 4px 12px; font-weight: bold; margin-left: 8px; }
            .icon-btn { background-color: transparent; display: flex; justify-content: center; align-items: center; width: 40px; height: 40px; border-radius: 50%; }
            .icon-btn.small { width: 32px; height: 32px; }
            .icon-btn:hover { background-color: rgba(0,0,0,0.05); }
            .fab { position: fixed; bottom: 80px; right: 20px; width: 56px; height: 56px; border-radius: 50%; background-color: #2196f3; color: white; font-size: 24px; display: flex; justify-content: center; align-items: center; box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
            
            /* Material Icons stand-in */
            i { font-style: normal; }
            
            /* Category Filter */
            .category-filter { display: flex; overflow-x: auto; padding: 16px; gap: 8px; background-color: white; }
            .chip { background-color: #f0f0f0; border-radius: 16px; padding: 4px 12px; font-size: 14px; white-space: nowrap; }
            .chip.selected { background-color: #2196f3; color: white; }
            
            /* Photo Grid */
            .photo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; padding: 16px; flex-grow: 1; margin-bottom: 60px; }
            .photo-item { aspect-ratio: 1/1; }
            .photo-placeholder { background-color: #e0e0e0; width: 100%; height: 100%; display: flex; justify-content: center; align-items: center; color: #999; }
            
            /* Content Area */
            .content { padding: 16px; margin-bottom: 60px; }
            .subheader { margin-bottom: 16px; }
            
            /* Category List */
            .category-list { display: flex; flex-direction: column; gap: 16px; }
            .category-item { display: flex; align-items: center; background-color: white; padding: 16px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
            .category-icon { width: 40px; height: 40px; border-radius: 50%; display: flex; justify-content: center; align-items: center; color: white; margin-right: 16px; }
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
            .section-header i { margin-right: 8px; color: #2196f3; }
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