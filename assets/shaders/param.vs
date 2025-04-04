#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

// Input uniform values
uniform mat4 mvp;
uniform mat4 user_mat = mat4(1.0);

// Output vertex attributes (to fragment shader)
out vec2 fragTexCoord;
out vec4 fragColor;
out float height;

// NOTE: Add your custom variables here

void main()
{
    // Send vertex attributes to fragment shader
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    // Calculate final vertex position
    vec4 pre_pos = user_mat*vec4(vertexPosition, 1.0);
    vec4 vertex_pos = mvp*pre_pos;
    fragColor = vec4(pre_pos.xyz, 1);

    gl_Position = vertex_pos;
    height = clamp(vertexPosition.y, 0.0, 1.0);
}