#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

//position of draw rect
// x = x, y = y, z = width, w = height
uniform vec4 position

//output color
out vec4 finalColor;

void main()
{
    vec2 pixelLocation = vec2(
            position.x + fragTexCoord.x * position.z,
            position.y + fragTexCoord.y * position.w);

    finalColor = texture(sampler2D, fragTexCoord);
}
