#version 420

// original https://www.shadertoy.com/view/7lSGDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec4 color = vec4(.0);

    vec2 res = resolution.xy;

    //------ create polar coordinates -----

    vec2 nUV = (uv - .5) * res / res.y * 1.3;

    vec2 V = normalize(nUV);

    vec2 refV = vec2(1., 0.);

    float cosA = dot(refV, V);

    float alpha = acos(cosA);

    alpha = alpha * step(.0, nUV.y) + (radians(360.) - alpha) * step(nUV.y, .0); // full 2PI circle

    //--------------------------------------

    float alphaP = alpha + length(nUV) * 16. / exp(length(nUV));

    float edge = cos(alphaP * 5. + time * 3.);

    edge += 1.;

    edge /= 2.;

    edge *= length(nUV) * exp(length(nUV) / 3.);

    vec3 rainbow;

    rainbow.r = (sin(alphaP - edge * 20. - time * 10. + radians(360.) * 0. / 360.) + 1.) / 2.;
    rainbow.g = (sin(alphaP - edge * 20. - time * 10. + radians(360.) * 120. / 360.) + 1.) / 2.;
    rainbow.b = (sin(alphaP - edge * 20. - time * 10. + radians(360.) *240. / 360.) + 1.) / 2.;

    color.rgb = rainbow * edge;

    color.a = 1.;

    // Output to screen
    glFragColor = color;
}
