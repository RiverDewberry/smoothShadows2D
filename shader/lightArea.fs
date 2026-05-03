#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

//position of draw rect
// x = x, y = y, z = width, w = height
uniform vec4 position;

// vec2(x, y) = start, vec2(z, y) = end
uniform vec4 lightPosition;

uniform float focus;

//output color
out vec4 finalColor;

bool isLeft(vec2 offset, vec4 line)
{
    return (line.z - line.x)*(offset.y - line.y) - (line.w - line.y)*(offset.x - line.x) >= 0.0f;
}

//is range engulfed by range2
bool isRangeEngulfed(vec2 range, vec2 range2)
{
    return ((range.x <= range.y) &&
        ((range.x >= range2.x && range.y <= range2.y) ||
        (range2.x >= range2.y && (range.x >= range2.x || range.y <= range2.y)))) ||
        (range.x >= range.y && range.x >= range2.x && range.y <= range2.y && range2.x >= range2.y);
}

vec2 getAngleRange(vec2 offset, vec4 line)
{
    return vec2(
            atan(line.y - offset.y, line.x - offset.x),
            atan(line.w - offset.y, line.z - offset.x));
}

vec3 shouldRedraw(vec2 location)
{
    if (isLeft(location, lightPosition)) return vec3(0.0f, 0.0f, 0.0f);

    vec2 lightRange = getAngleRange(location, lightPosition);
    if (abs(lightRange.x - lightRange.y) < 0.00001f) return vec3(0.0f, 0.0f, 0.0f);

    float angleAccumulator = lightRange.y;
    float endAngle = lightRange.x;
    
    if (focus <= 0.0001f)
    {
        // the arctan of the normal of the direction vector of the line
        float taotnotdvotl = atan(
           lightPosition.z - lightPosition.x, lightPosition.y - lightPosition.w
        );

        if (endAngle >= angleAccumulator)
        {
            if (taotnotdvotl >= angleAccumulator && taotnotdvotl <= endAngle)
                return vec3(1.0f, 1.0f, 1.0f);
            else return vec3(0.0f, 0.0f, 0.0f);
        } else {
            if (taotnotdvotl < angleAccumulator && taotnotdvotl > endAngle)
                return vec3(0.0f, 0.0f, 0.0f);
            else return vec3(1.0f, 1.0f, 1.0f);
        }

    } else if (lightColor.w != 1.0f)
    {
        // the arctan of the normal of the direction vector of the line
        float shadowCenterAngle = atan(
           lightPosition.z - lightPosition.x, lightPosition.y - lightPosition.w
        );

        float shadowStartAngle = shadowCenterAngle + lightColor.w * HALF_PI;
        float shadowEndAngle = shadowCenterAngle - lightColor.w * HALF_PI;

        // make sure angles are in proper range
        shadowStartAngle = mod(shadowStartAngle - PI, TWO_PI) - PI;
        shadowEndAngle = mod(shadowEndAngle - PI, TWO_PI) - PI;

        if (isRangeEngulfed(
                    vec2(angleAccumulator, endAngle),
                    vec2(shadowStartAngle, shadowEndAngle))
           ) return vec3(0.0f, 0.0f, 0.0f);
    }

    return vec3(1.0f, 1.0f, 1.0f);
}

void main()
{
    vec2 pixelLocation = vec2(
            position.x + fragTexCoord.x * position.z,
            position.y + fragTexCoord.y * position.w);

    finalColor = vec4(getLocalLight(pixelLocation), 1.0f);
}
