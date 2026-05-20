#version 330

#define PI 3.14159265359f
#define TWO_PI 6.28318530718f
#define HALF_PI 1.57079632679f
#define ONE_OVER_PI 0.318309886184;

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

//position of draw rect
// x = x, y = y, z = width, w = height
uniform vec4 position;

// vec2(x, y) = start, vec2(z, y) = end
uniform vec4 lightPosition;

// vec2(x, y) = start, vec2(z, y) = end
uniform vec4 shadowPosition;

uniform float focus;

//output color
out vec4 finalColor;

bool isLeft(vec2 offset, vec4 line)
{
    return (line.z - line.x)*(offset.y - line.y) - (line.w - line.y)*(offset.x - line.x) > 0.05f;
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

bool inLight(vec2 location)
{
    if (isLeft(location, lightPosition)) return false;
    if (isLeft(location, shadowPosition)) return false;

    vec2 lightRange = getAngleRange(location, lightPosition);
    if (abs(lightRange.x - lightRange.y) < 0.00001f) return false;

    vec2 shadowRange = getAngleRange(location, shadowPosition);
    if (abs(shadowRange.x - shadowRange.y) < 0.00001f) return false;

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
            if (taotnotdvotl + 0.01f >= angleAccumulator && taotnotdvotl <= endAngle + 0.01f)
                return true;
            else return false;
        } else {
            if (taotnotdvotl + 0.01f <= angleAccumulator && taotnotdvotl >= endAngle + 0.01f)
                return false;
            else return true;
        }

    } else if (focus != 1.0f)
    {
        // the arctan of the normal of the direction vector of the line
        float shadowCenterAngle = atan(
           lightPosition.z - lightPosition.x, lightPosition.y - lightPosition.w
        );

        float shadowStartAngle = shadowCenterAngle + focus * HALF_PI;
        float shadowEndAngle = shadowCenterAngle - focus * HALF_PI;

        // make sure angles are in proper range
        shadowStartAngle = mod(shadowStartAngle - PI, TWO_PI) - PI;
        shadowEndAngle = mod(shadowEndAngle - PI, TWO_PI) - PI;

        if (isRangeEngulfed(
                    vec2(angleAccumulator, endAngle),
                    vec2(shadowStartAngle, shadowEndAngle))
           ) return false;
    }

    return true;
}

bool inShadow(vec2 location)
{
    if (isLeft(location, vec4(lightPosition.xy, shadowPosition.zw))) return false;
    if (isLeft(location, vec4(lightPosition.zw, shadowPosition.xy))) return false;
    
    return true;
}

void main()
{
    vec2 pixelLocation = vec2(
            position.x + fragTexCoord.x * position.z,
            position.y + fragTexCoord.y * position.w);

    finalColor = vec4(0.0f, 0.0f, 0.0f, 0.0f);

    if (inLight(pixelLocation))
    {
        if (inShadow(pixelLocation)) finalColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
    }
}
