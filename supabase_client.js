// Initialize Supabase client
// Using script version for browser
// Note: in a production setup, we would use a proper frontend build system

// Values loaded from environment variables via server injection
const supabaseUrl = window.SUPABASE_URL; 
const supabaseKey = window.SUPABASE_KEY;

// Create a single supabase client for interacting with your database
// The global supabase object is available from the CDN
const supabase = window.supabase.createClient(supabaseUrl, supabaseKey);

// Authentication functions
// Create a global object to expose functions
window.galleryzeApi = {};

// Default categories to set up for new users
const DEFAULT_CATEGORIES = [
  { id: 'docs-1001', name: 'Docs', icon: 'orange' },
  { id: 'family-1002', name: 'Family', icon: 'green' },
  { id: 'food-1003', name: 'Food', icon: 'amber' },
  { id: 'nature-1004', name: 'Nature', icon: 'green' }
];

// Authentication functions
galleryzeApi.signUp = async function(email, password, name) {
  // Set up default categories for new users
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: name,
        categories: DEFAULT_CATEGORIES
      }
    }
  });
  return { data, error };
};

galleryzeApi.signIn = async function(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  return { data, error };
};

galleryzeApi.signOut = async function() {
  const { error } = await supabase.auth.signOut();
  return { error };
};

galleryzeApi.getCurrentUser = async function() {
  const { data: { user } } = await supabase.auth.getUser();
  
  // Return user with metadata
  if (user && user.user_metadata && user.user_metadata.full_name) {
    // If we have user metadata with full_name, use it
    user.display_name = user.user_metadata.full_name;
    
    // Check if categories are already in user metadata
    if (!user.user_metadata.categories) {
      // If not, update user metadata with default categories
      await galleryzeApi.updateUserCategories(DEFAULT_CATEGORIES);
    }
  } else if (user) {
    // Fallback to email or random id if no name is available
    user.display_name = user.email ? user.email.split('@')[0] : `User ${user.id.substring(0, 6)}`;
  }
  
  return user;
};

// Database operations
galleryzeApi.savePhotoCategory = async function(userId, photoId, categories) {
  // First check if entry exists
  const { data: existingData } = await supabase
    .from('photo_categories')
    .select('*')
    .eq('user_id', userId)
    .eq('photo_id', photoId)
    .single();

  if (existingData) {
    // Update existing record
    const { data, error } = await supabase
      .from('photo_categories')
      .update({ categories })
      .eq('user_id', userId)
      .eq('photo_id', photoId);
    return { data, error };
  } else {
    // Insert new record
    const { data, error } = await supabase
      .from('photo_categories')
      .insert([
        { user_id: userId, photo_id: photoId, categories }
      ]);
    return { data, error };
  }
};

galleryzeApi.getPhotoCategories = async function(userId, photoId = null) {
  let query = supabase
    .from('photo_categories')
    .select('*')
    .eq('user_id', userId);
  
  if (photoId) {
    query = query.eq('photo_id', photoId);
  }
  
  const { data, error } = await query;
  return { data, error };
};

galleryzeApi.saveFavorite = async function(userId, photoId, isFavorite) {
  // First check if entry exists
  const { data: existingData } = await supabase
    .from('photo_favorites')
    .select('*')
    .eq('user_id', userId)
    .eq('photo_id', photoId)
    .single();

  if (existingData) {
    // Update existing record
    const { data, error } = await supabase
      .from('photo_favorites')
      .update({ is_favorite: isFavorite })
      .eq('user_id', userId)
      .eq('photo_id', photoId);
    return { data, error };
  } else {
    // Insert new record
    const { data, error } = await supabase
      .from('photo_favorites')
      .insert([
        { user_id: userId, photo_id: photoId, is_favorite: isFavorite }
      ]);
    return { data, error };
  }
};

galleryzeApi.getFavorites = async function(userId) {
  const { data, error } = await supabase
    .from('photo_favorites')
    .select('*')
    .eq('user_id', userId)
    .eq('is_favorite', true);
  
  return { data, error };
};

// Category Management in User Metadata
galleryzeApi.getUserCategories = async function() {
  const { data: { user } } = await supabase.auth.getUser();
  if (user && user.user_metadata && user.user_metadata.categories) {
    return user.user_metadata.categories;
  }
  // Return default categories if user has none
  return DEFAULT_CATEGORIES;
};

galleryzeApi.updateUserCategories = async function(categories) {
  const { data, error } = await supabase.auth.updateUser({
    data: { categories }
  });
  return { data, error };
};

galleryzeApi.createCategory = async function(categoryName) {
  // Generate unique ID
  const categoryId = `${categoryName.toLowerCase().replace(/\s+/g, '-')}-${Date.now().toString().slice(-4)}`;
  
  // Assign a random color from available options
  const colors = ['blue', 'red', 'green', 'purple', 'orange', 'amber'];
  const randomColor = colors[Math.floor(Math.random() * colors.length)];
  
  const newCategory = {
    id: categoryId,
    name: categoryName,
    icon: randomColor
  };
  
  // Get current categories
  const categories = await galleryzeApi.getUserCategories();
  
  // Add new category
  categories.push(newCategory);
  
  // Update user metadata
  const { data, error } = await galleryzeApi.updateUserCategories(categories);
  
  if (error) {
    return { success: false, error };
  }
  
  return { success: true, category: newCategory };
};

galleryzeApi.updateCategory = async function(categoryId, categoryName) {
  // Get current categories
  const categories = await galleryzeApi.getUserCategories();
  
  // Find and update the category
  const categoryIndex = categories.findIndex(cat => cat.id === categoryId);
  
  if (categoryIndex === -1) {
    return { success: false, error: { message: 'Category not found' } };
  }
  
  // Update the name but keep the same icon/color
  categories[categoryIndex].name = categoryName;
  
  // Update user metadata
  const { data, error } = await galleryzeApi.updateUserCategories(categories);
  
  if (error) {
    return { success: false, error };
  }
  
  return { success: true, category: categories[categoryIndex] };
};

galleryzeApi.deleteCategory = async function(categoryId) {
  // Get current categories
  const categories = await galleryzeApi.getUserCategories();
  
  // Filter out the category to delete
  const updatedCategories = categories.filter(cat => cat.id !== categoryId);
  
  // If no change in length, category wasn't found
  if (categories.length === updatedCategories.length) {
    return { success: false, error: { message: 'Category not found' } };
  }
  
  // Update user metadata
  const { data, error } = await galleryzeApi.updateUserCategories(updatedCategories);
  
  if (error) {
    return { success: false, error };
  }
  
  return { success: true };
};