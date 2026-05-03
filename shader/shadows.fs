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

// vec3(x, y, z) = rgb color, w = focus
uniform vec4 lightColor;

uniform sampler2D texture0;
uniform sampler2D texture1;

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

bool doRangesTouch(vec2 range, vec2 range2)
{
    return (range.x <= range.y &&
        ((range2.x >= range.x && range2.x <= range.y) ||
        (range2.y >= range.x && range2.y <= range.y))) ||
        ((range.x >= range.y) &&
        ((range.y >= range2.x) || (range.x <= range2.y) ||
        ((range2.x > range2.y) && ((range.y > range2.y) || (range.x < range2.x)))));
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
    if (abs(lightRange.x - lightRange.y) < 0.00001f) return vec3(0.0f, 0.0f, 0.0f);

    float angleAccumulator = lightRange.y;
    float endAngle = lightRange.x;
    
    if (lightColor.w <= 0.0001f)
    {
        // the arctan of the normal of the direction vector of the line
        float taotnotdvotl = atan(
           lightPosition.z - lightPosition.x, lightPosition.y - lightPosition.w
        );

        if (endAngle >= angleAccumulator)
        {
            if (taotnotdvotl > angleAccumulator && taotnotdvotl < endAngle)
                return lightColor.xyz;
            else return vec3(0.0f, 0.0f, 0.0f);
        } else {
            if (taotnotdvotl < angleAccumulator && taotnotdvotl > endAngle)
                return vec3(0.0f, 0.0f, 0.0f);
            else return lightColor.xyz;
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

        if (doRangesTouch(
                    vec2(angleAccumulator, endAngle),
                    vec2(shadowStartAngle, shadowEndAngle))
           )
        {
            if (angleAccumulator <= endAngle)
            {
                if (shadowStartAngle <= shadowEndAngle)
                {
                    if (angleAccumulator >= shadowStartAngle) angleAccumulator = shadowEndAngle;
                    else endAngle = shadowStartAngle;
                } else {
                    if (angleAccumulator <= shadowEndAngle) angleAccumulator = shadowEndAngle;
                    if (endAngle >= shadowStartAngle) endAngle = shadowStartAngle;
                }
            } else {
                if (shadowStartAngle <= shadowEndAngle)
                {
                    angleAccumulator = max(angleAccumulator, shadowEndAngle);
                    endAngle = min(endAngle, shadowStartAngle);
                } else {
                    if (shadowStartAngle <= angleAccumulator)
                    {
                        angleAccumulator = shadowEndAngle;
                        if (shadowStartAngle <= endAngle) endAngle = shadowStartAngle;

                    } else
                    {
                        endAngle = shadowStartAngle;
                        if (shadowEndAngle >= angleAccumulator) angleAccumulator = shadowEndAngle;
                    }
                }
            }
        }
    }

    vec3 colorAccumulator = vec3(0.0f, 0.0f, 0.0f);

    while (angleAccumulator != endAngle)
    {
        float nextAngle = PI;

        if (endAngle >= angleAccumulator) nextAngle = endAngle;

        colorAccumulator += lightColor.rgb * (nextAngle - angleAccumulator);

        if (nextAngle == PI) angleAccumulator = -PI;
        else angleAccumulator = nextAngle;
    }

    return (colorAccumulator / lightColor.w) * ONE_OVER_PI;
}

void main()
{
    if (texture(texture0, fragTexCoord).r == 0.0f)
    {
        finalColor = vec4(0.0f,0.0f,0.0f,1.0f);
        return;
    }

    vec2 pixelLocation = vec2(
            position.x + fragTexCoord.x * position.z,
            position.y + (1 - fragTexCoord.y) * position.w);

    finalColor = vec4(getLocalLight(pixelLocation), 1.0f);
}
