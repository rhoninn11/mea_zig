#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;
in float height;

// Input uniform values
uniform vec4 user_color = vec4(0.098, 0.5373, 0.7137, 1.0);

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here

const float ZERO = 0.0000001;
// Convert texel color to grayscale using NTSC conversion weights
    // Convert texel color to grayscale using NTSC conversion weights
// vec3 monochrom = vec3(0.299, 0.587, 0.114);

void main()
{   
    // Calculate final fragment color
    finalColor = vec4(user_color.xyz, 1);
}