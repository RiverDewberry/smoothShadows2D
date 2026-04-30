#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

//position of draw rect
// x = x, y = y, z = width, w = height
uniform vec4 position;

// vec2(x, y) = start, vec2(z, y) = end
uniform vec4 lightPosition;

// vec3(x, y, z) = rgb color, w = focus
uniform vec4 lightColor;

//output color
out vec4 finalColor;

bool isLeft(vec2 offset, vec4 line)
{
    return (line.z - line.x)*(offset.y - line.y) - (line.w - line.y)*(offset.x - line.x) > 0.0f;
}

vec2 getAngleRange(vec2 offset, vec4 line)
{
    return vec2(
            atan(line.y - offset.y, line.x - offset.x),
            atan(line.w - offset.y, line.z - offset.x));
}

vec3 getLocalLight(vec2 location)
{
    if (isLeft(location, lightPosition)) return vec3(0.0f, 0.0f, 0.0f);

    vec2 lightRange = getAngleRange(location, lightPosition);

    if (abs(lightRange.x - lightRange.y) < 0.0001f) return vec3(0.0f, 0.0f, 0.0f);

    vec3 colorAccumulator = vec3(0.0f, 0.0f, 0.0f);
    
    float angleAccumulator = lightRange.y;
    float endAngle = lightRange.x;
    float PI = 3.14159265359f;

    while (angleAccumulator != endAngle)
    {
        float nextAngle = PI;

        if (endAngle >= angleAccumulator) nextAngle = endAngle;

        colorAccumulator += lightColor.rgb * (nextAngle - angleAccumulator);

        if (nextAngle == PI) angleAccumulator = -PI;
        else angleAccumulator = nextAngle;
    }

    return colorAccumulator * 0.318309886184f; // 1/PI
}

void main()
{
    vec2 pixelLocation = vec2(
            position.x + fragTexCoord.x * position.z,
            position.y + fragTexCoord.y * position.w);

    finalColor = vec4(getLocalLight(pixelLocation), 1.0f);
}
