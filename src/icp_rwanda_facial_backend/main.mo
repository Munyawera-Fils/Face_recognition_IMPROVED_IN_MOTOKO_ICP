import Array "mo:base/Array";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

actor {
  // Define the user type
  public type User = {
    email: Text;
    password: Text; // Stored in plain text as requested
    image: Text; // Base64-encoded image
  };

  // Stable variable to store user accounts
  stable var users: [User] = [];

  // Function to create a new user account or update the image if the account exists
  public func addOrUpdateUser(email: Text, password: Text, base64Image: Text): async Bool {
    let existingUser = Array.find<User>(users, func (user) {
      user.email == email
    });
    
    switch (existingUser) {
      case (?user) {
        // Update existing user's image
        users := Array.filter<User>(users, func (u) { u.email != email });
        users := Array.append(users, [{
          email = user.email;
          password = user.password;
          image = base64Image;
        }]);
        return true;
      };
      case null {
        // Add a new user
        let newUser: [User] = [{
          email;
          password;
          image = base64Image;
        }];
        users := Array.append(users, newUser);
        return true;
      };
    };
  };

  // Function to retrieve the stored image by email
  public query func getImage(email: Text): async ?Text {
    let user = Array.find<User>(users, func (u) { u.email == email });
    switch (user) {
      case (?u) { return ?u.image; };
      case null { return null; };
    }
  };

  // Function to delete the stored image by email
  public func deleteImage(email: Text): async Bool {
    let user = Array.find<User>(users, func (u) { u.email == email });
    switch (user) {
      case (?u) {
        users := Array.filter<User>(users, func (u) { u.email != email });
        let updatedUser: [User] = [{
          email = u.email;
          password = u.password;
          image = ""; // Clear stored image
        }];
        users := Array.append(users, updatedUser);
        return true;
      };
      case null { return false; };
    }
  };

  // Function to verify login credentials (email and password)
  public query func login(email: Text, password: Text): async Bool {
    let user = Array.find<User>(users, func (u) {
      u.email == email and u.password == password
    });
    return user != null;
  };

  // Placeholder function for image comparison logic
  public func compareImages(storedImage: Text, newImage: Text): async Bool {
    return storedImage == newImage;
  };
};
