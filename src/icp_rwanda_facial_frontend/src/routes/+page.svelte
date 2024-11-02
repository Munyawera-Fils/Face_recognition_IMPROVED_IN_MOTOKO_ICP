<script>
  import { backend } from "$lib/canisters";
  import { onMount } from "svelte";
  let video;
  let canvas;
  let userImage = null;
  let base64Image = null;
  let loading = false;
  let isLoggedIn = false;
  let timer = 0;
  let isSameUser = true;
  let isSessionActive = false;

  let signupEmail = '';
  let signupPassword = '';
  let loginEmail = '';
  let loginPassword = '';
  let logMessage = '';
  let isCheckingUser = false;

  const signup = async () => {
    const success = await backend.addOrUpdateUser(signupEmail, signupPassword, "");
    if (success) {
      alert("Account created successfully! Please log in.");
    } else {
      alert("Account creation failed or account already exists.");
    }
  };

  const login = async () => {
    isLoggedIn = await backend.login(loginEmail, loginPassword);
    if (isLoggedIn) {
      alert("Login successful!");
      await fetchStoredImage();
      logMessage = '';
    } else {
      alert("Invalid login credentials.");
    }
  };

  const logout = () => {
    stopManagedSession();
    isLoggedIn = false;
    loginEmail = '';
    loginPassword = '';
    alert("Logged out successfully.");
  };

  const fetchStoredImage = async () => {
    const storedImage = await backend.getImage(loginEmail);
    if (storedImage) {
      userImage = `data:image/png;base64,${storedImage}`;
    }
  };

  const startCamera = async () => {
    loading = true;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      video.srcObject = stream;
      video.play();
      loading = false;
    } catch (error) {
      console.error("Error accessing camera:", error);
      loading = false;
    }
  };

  const captureImage = () => {
    const context = canvas.getContext("2d");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    context.drawImage(video, 0, 0);
    base64Image = canvas.toDataURL("image/png").split(",")[1];
    userImage = canvas.toDataURL("image/png");
  };

  const uploadImage = async () => {
    if (base64Image) {
      const success = await backend.addOrUpdateUser(loginEmail, loginPassword, base64Image);
      if (success) {
        alert("Image uploaded successfully!");
      } else {
        alert("Failed to upload image.");
      }
    }
  };

  const compareImages = async () => {
    isCheckingUser = true;
    logMessage = "Checking user identity...";

    try {
      const response = await fetch('http://54.225.49.40:5005/compare-base', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          known_image: userImage.split(",")[1],
          unknown_image: base64Image,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'An error occurred during comparison');
      }

      const data = await response.json();
      isSameUser = data.match;

      logMessage = isSameUser ?
        "User identity confirmed. You are still logged in." :
        "User identity could not be confirmed. Please log in again.";

      if (!isSameUser) stopManagedSession();
    } catch (error) {
      logMessage = `Error: ${error.message}`;
      stopManagedSession();
      console.error(error);
    } finally {
      isCheckingUser = false;
    }
  };

  let interval;
  let interval_compare;

  const startManagedSession = () => {
    if (loading) {
      alert("Please wait for the camera to load.");
      return;
    }

    isSessionActive = true;
    timer = 0;
    interval = setInterval(() => timer++, 1000);
    interval_compare = setInterval(() => {
      captureImage();
      compareImages();
    }, 10000);
  };

  const stopManagedSession = () => {
    clearInterval(interval);
    clearInterval(interval_compare);
    isSessionActive = false;
    timer = 0;
    const stream = video.srcObject;
    if (stream) {
      const tracks = stream.getTracks();
      tracks.forEach(track => track.stop());
      video.srcObject = null;
    }
  };

  onMount(() => {
    if (isLoggedIn) startCamera();
  });
</script>

<style>
  .container {
    max-width: 600px;
    margin: auto;
    padding: 1rem;
  }
  .hidden { display: none; }
  .row-display { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; }
  .loading-indicator { color: blue; font-weight: bold; }
  @media (max-width: 768px) {
    .row-display img, .row-display video {
      width: 100%;
    }
    .text-center { font-size: 1.2em; }
  }
</style>

<div class="container">
  {#if !isLoggedIn}
    <div class="text-center mt-5">
      <h1>Welcome to ICP Rwanda Facial Recognition</h1>
      <p>Sign up or log in to get started.</p>
    </div>

    <div class="row mt-5">
      <div class="col-md-6">
        <h2>Sign Up</h2>
        <form on:submit|preventDefault={signup}>
          <div class="mb-3">
            <label class="form-label">Email</label>
            <input type="email" bind:value={signupEmail} class="form-control" required>
          </div>
          <div class="mb-3">
            <label class="form-label">Password</label>
            <input type="password" bind:value={signupPassword} class="form-control" required>
          </div>
          <button type="submit" class="btn btn-success w-100">Sign Up</button>
        </form>
      </div>

      <div class="col-md-6">
        <h2>Log In</h2>
        <form on:submit|preventDefault={login}>
          <div class="mb-3">
            <label class="form-label">Email</label>
            <input type="email" bind:value={loginEmail} class="form-control" required>
          </div>
          <div class="mb-3">
            <label class="form-label">Password</label>
            <input type="password" bind:value={loginPassword} class="form-control" required>
          </div>
          <button type="submit" class="btn btn-primary w-100">Log In</button>
        </form>
      </div>
    </div>
  {/if}

  {#if isLoggedIn}
    <div class="mt-5">
      <h2>Managed Session</h2>
      <p>Session Time: {timer}s</p>
      <p class="loading-indicator">{isCheckingUser ? 'Checking user identity...' : logMessage}</p>
      
      <button class="btn btn-secondary mb-3" on:click={startCamera}>Start Camera</button>
      <button class="btn btn-success mb-3" on:click={startManagedSession} disabled={loading || isSessionActive}>Start Managed Session</button>
      <button class="btn btn-danger mb-3" on:click={stopManagedSession} disabled={!isSessionActive}>Stop Managed Session</button>
      
      {#if loading}
        <div class="alert alert-info">Loading camera...</div>
      {/if}

      <div class="row-display mb-3">
        {#if userImage}
          <img src={userImage} alt="Stored User Image" class="img-thumbnail" style="width: 45%;" />
        {/if}
        <video bind:this={video} autoplay class="img-thumbnail" style="width: 45%;"></video>
      </div>

      <canvas bind:this={canvas} class="hidden"></canvas>
      
      <button class="btn btn-warning w-100 mb-2" on:click={captureImage}>Capture Image</button>
      <button class="btn btn-primary w-100 mb-2" on:click={uploadImage}>Upload Image</button>
      <button class="btn btn-outline-danger w-100 mb-2" on:click={logout}>Logout</button>

      {#if !isSameUser}
        <div class="alert alert-danger">User identity could not be confirmed. Please log in again.</div>
      {/if}
    </div>
  {/if}

  <footer class="text-center mt-5">
    <p>&copy; Developed by the ICP Rwanda Team</p>
  </footer>
</div>
