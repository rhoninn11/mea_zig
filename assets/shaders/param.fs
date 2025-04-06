#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;
in float height;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec4 user_color = vec4(0,0,0,0);

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here

const float ZERO = 0.0000001;
// Convert texel color to grayscale using NTSC conversion weights
    // Convert texel color to grayscale using NTSC conversion weights
// vec3 monochrom = vec3(0.299, 0.587, 0.114);

void main()
{   
    // Texel color fetching from texture sampler
    vec4 tex_col = texture(texture0, fragTexCoord)*colDiffuse*fragColor;
    vec4 tex_col_mute = ZERO*tex_col;

    vec4 world_pos = fragColor+tex_col_mute;
    // imaginary clip plane on z axis at hi
    float slice_mask = 1 - step(0.23, world_pos.y);
    
    // Calculate final fragment color
    finalColor = vec4(user_color.xyz, slice_mask);
}