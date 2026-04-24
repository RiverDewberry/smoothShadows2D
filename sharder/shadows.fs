#version 330

// Input vertex attributes (from vertex shader)
in vec3 vertexPos;
in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

void main()
{
    finalColor = vec4(0.0f, 0.0f, 0.0f, 0.0f);
}
