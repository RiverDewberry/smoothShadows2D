#version 330

#define PI 3.14159265359f
#define TWO_PI 6.28318530718f
#define HALF_PI 1.57079632679f
#define ONE_OVER_PI 0.318309886184

#define SHADOW_MAX 16

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

//position of draw rect
// x = x, y = y, z = width, w = height
uniform vec4 position;

// vec2(x, y) = start, vec2(z, y) = end
uniform vec4 lightPosition;

// vec3(x, y, z) = rgb color, w = focus
uniform vec4 color;

uniform sampler2D texture0;
uniform sampler2D texture1;

uniform sampler2D shadowData;
uniform int shadowCount;

//output color
out vec4 finalColor;

vec2 rangeArr[SHADOW_MAX];
vec4 colorArr[SHADOW_MAX];

bool isLeft(vec2 offset, vec4 line)
{
    return (line.z - line.x)*(offset.y - line.y) - (line.w - line.y)*(offset.x - line.x) > 0.0f;
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

bool pointInRange(vec2 range, float point)
{
    return (
        (range.x > range.y) && (point > range.x || point <= range.y)
    ) || (
        (range.x < range.y) && (point <= range.y && point > range.x)
    );
}

bool linesIntersect(vec2 p1, vec2 p2, vec2 p3, vec2 p4)
{
    return (
        (isLeft(p3, vec4(p1, p2))) !=
        isLeft(p4, vec4(p1, p2)) &&
        (isLeft(p1, vec4(p3, p4))) !=
        isLeft(p2, vec4(p3, p4))
    );
}

float sign (vec2 p1, vec2 p2, vec2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool pointInTriangle (vec2 pt, vec2 v1, vec2 v2, vec2 v3)
{
    float d1, d2, d3;
    bool has_neg, has_pos;

    d1 = sign(pt, v1, v2);
    d2 = sign(pt, v2, v3);
    d3 = sign(pt, v3, v1);

    has_neg = (d1 < 0.0f) || (d2 < 0.0f) || (d3 < 0.0f);
    has_pos = (d1 > 0.0f) || (d2 > 0.0f) || (d3 > 0.0f);

    return !(has_neg && has_pos);
}

bool inShadow(vec4 shadow, vec4 light, vec2 point)
{
    if (
            linesIntersect(shadow.xy, shadow.zw, point, light.xy) ||
            linesIntersect(shadow.xy, shadow.zw, point, light.zw)
       ) return true;

    if (
        pointInTriangle(shadow.xy, light.xy, light.zw, point) ||
        pointInTriangle(shadow.zw, light.xy, light.zw, point)
    ) return true;

    return false;
}

vec3 getLocalLight(vec2 location)
{
    if (isLeft(location, lightPosition)) return vec3(0.0f, 0.0f, 0.0f);

    vec2 lightRange = getAngleRange(location, lightPosition);
    if (abs(lightRange.x - lightRange.y) < 0.00001f) return vec3(0.0f, 0.0f, 0.0f);

    float angleAccumulator = lightRange.y;
    float endAngle = lightRange.x;

    vec4 lightColor = color;
    
    if (lightColor.w <= 0.0001f)
    {
        // the arctan of the normal of the direction vector of the line
        float taotnotdvotl = atan(
           lightPosition.z - lightPosition.x, lightPosition.y - lightPosition.w
        );

        if (endAngle >= angleAccumulator)
        {
            if (!(taotnotdvotl > angleAccumulator && taotnotdvotl < endAngle))
                return vec3(0.0f, 0.0f, 0.0f);
        } else {
            if (taotnotdvotl < angleAccumulator && taotnotdvotl > endAngle)
                return vec3(0.0f, 0.0f, 0.0f);
        }

        vec3 retColor = color.rgb;

        for (int i = 0; i < shadowCount; i++)
        {
            vec4 temp = texelFetch(shadowData, ivec2(0, i), 0);
            if (isLeft(location, temp)) continue;
            if (!inShadow(temp, lightPosition, location)) continue;

            vec2 tempRange = getAngleRange(location, temp);

            if (pointInRange(tempRange, taotnotdvotl)) continue;

            if (abs(tempRange.x - tempRange.y) < 0.00001f) continue;

            vec3 tempColor = texelFetch(shadowData, ivec2(1, i), 0).rgb;

            retColor.r *= tempColor.r;
            retColor.g *= tempColor.g;
            retColor.b *= tempColor.b;
        }

        return retColor;
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

    int realShadows = 0;
    for (int i = 0; i < shadowCount; i++)
    {
        vec4 temp = texelFetch(shadowData, ivec2(0, i), 0);
        if (isLeft(location, temp)) continue;
        if (!inShadow(temp, lightPosition, location)) continue;

        rangeArr[realShadows] = getAngleRange(location, temp);

        if (abs(rangeArr[realShadows].x - rangeArr[realShadows].y) < 0.00001f)
            continue;

        colorArr[realShadows] = texelFetch(shadowData, ivec2(1, i), 0);

        if (isRangeEngulfed(
                    vec2(angleAccumulator, endAngle),
                    vec2(rangeArr[realShadows].y, rangeArr[realShadows].x))
        )
        {
            lightColor.r *= colorArr[realShadows].r;
            lightColor.g *= colorArr[realShadows].g;
            lightColor.b *= colorArr[realShadows].b;
        }

        if (!doRangesTouch(
                    vec2(angleAccumulator, endAngle),
                    vec2(rangeArr[realShadows].x, rangeArr[realShadows].y))
        ) continue;

        realShadows++;
    }

    vec3 colorAccumulator = vec3(0.0f, 0.0f, 0.0f);

    while (angleAccumulator != endAngle)
    {
        float nextAngle = PI;

        if (endAngle >= angleAccumulator) nextAngle = endAngle;
        
        for (int i = 0; i < realShadows; i++)
        {
            if (rangeArr[i].x > angleAccumulator && rangeArr[i].x < nextAngle)
                nextAngle = rangeArr[i].x;

            if (rangeArr[i].y > angleAccumulator && rangeArr[i].y < nextAngle)
                nextAngle = rangeArr[i].y;
        }

        vec3 tempColor = lightColor.rgb;

        for (int i = 0; i < realShadows; i++)
        {
            if (pointInRange(rangeArr[i].yx, nextAngle))
            {
                tempColor.r *= colorArr[i].r;
                tempColor.g *= colorArr[i].g;
                tempColor.b *= colorArr[i].b;
            }
        }

        colorAccumulator += tempColor * (nextAngle - angleAccumulator);

        if (nextAngle == PI) angleAccumulator = -PI;
        else angleAccumulator = nextAngle;
    }

    return (colorAccumulator / lightColor.w) * ONE_OVER_PI;
}

void main()
{
    if (texture(texture0, fragTexCoord).r == 0.0f)
    {
        finalColor = vec4(0.0f,0.0f,0.0f,0.0f);
        return;
    }

    vec2 pixelLocation = vec2(
            position.x + fragTexCoord.x * position.z,
            position.y + (1 - fragTexCoord.y) * position.w);

    finalColor = vec4(getLocalLight(pixelLocation), 1.0f);
}
