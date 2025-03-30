#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;
in float height;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec4 draw_color = vec4(0,0,0,0);

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here

void main()
{
    // Texel color fetching from texture sampler
    vec4 tex_col = texture(texture0, fragTexCoord)*colDiffuse*fragColor;

    // Convert texel color to grayscale using NTSC conversion weights
    float gray = dot(tex_col.rgb, vec3(0.299, 0.587, 0.114))*0.9;
    vec3 gray_col = vec3(gray, gray, gray);
    vec3 mixed_col = tex_col.rgb * height + gray_col * (1-height);

    
    // Calculate final fragment color
    finalColor = vec4(draw_color.xyz, tex_col.a);
}