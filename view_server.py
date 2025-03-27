import simple_server

# Print out the get_home_page method to see the source code
home_page = simple_server.GalleryzeHandler.get_home_page
print(home_page.__code__.co_consts[1])