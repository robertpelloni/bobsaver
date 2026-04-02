// https://softologyblog.wordpress.com/2020/11/30/creating-glsl-animated-gif-loops/

#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float animationSeconds = 2.0; // how long do we want the animation to last before looping
float piTimes2 = 3.1415926536*2.0;

vec2 rotate(vec2 v, float a) {
    float angleInRadians = radians(a);
    float s = sin(angleInRadians);
    float c = cos(angleInRadians);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float checker(in float u, in float v, in float checksPerUnit)
{
  float fmodResult = mod(floor(checksPerUnit * u) + floor(checksPerUnit * v), 2.0);
  float col = max(sign(fmodResult), 0.0);
  return col;
}

void main(void)
{
    //uv is pixel coordinates between -1 and +1 in the X and Y axiis with aspect ratio correction
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    // sineVal is a floating point value between 0 and 1
    // starts at 0 when time = 0 then increases to 1.0 when time is half of animationSeconds and then back to 0 when time equals animationSeconds
    float sineVal = sin(piTimes2*(time-0.75)/animationSeconds)/2.0+0.5; 

    //rotate the uv coordinates between 0 and 180 degrees during the animationSeconds time length
    vec2 rotated_uv = rotate(uv,time/animationSeconds*180);
    vec2 rotated_uv2 = rotate(uv,-time/animationSeconds*180);

    //get the pixel checker color by passing the rotated coordinate into the checker function
    vec4 color = vec4(checker(uv.x, uv.y, 5.0 * sineVal),checker(rotated_uv.x, rotated_uv.y, 3.0 * sineVal),checker(rotated_uv2.x, rotated_uv2.y, 4.0 * sineVal),1.0);

    glFragColor = color;
}
