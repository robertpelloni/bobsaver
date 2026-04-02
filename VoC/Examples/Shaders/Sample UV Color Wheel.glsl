#version 420

// original https://www.shadertoy.com/view/4d2fzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 3.14159265358979323846264;

vec3 RGB_fromHSV(vec3 HSV)
{
    vec3 retCol;
    if ( HSV.y == 0.0 )
    {
       retCol.x = HSV.z;
       retCol.y = HSV.z;
       retCol.z = HSV.z;
    }
    else
    {
       float var_h = HSV.x * 6.0;
       if ( var_h == 6.0 ) {var_h = 0.0;}     //H must be < 1
       float var_i = floor( var_h );             //Or ... var_i = floor( var_h )
       float var_1 = HSV.z * ( 1.0 - HSV.y );
       float var_2 = HSV.z * ( 1.0 - HSV.y * ( var_h - var_i ) );
       float var_3 = HSV.z * ( 1.0 - HSV.y * ( 1.0 - ( var_h - var_i ) ) );
       if      ( var_i == 0.0 ) { retCol.x = HSV.z     ; retCol.y = var_3 ; retCol.z = var_1; }
       else if ( var_i == 1.0 ) { retCol.x = var_2 ; retCol.y = HSV.z ; retCol.z = var_1; }
       else if ( var_i == 2.0 ) { retCol.x = var_1 ; retCol.y = HSV.z ; retCol.z = var_3; }
       else if ( var_i == 3.0 ) { retCol.x = var_1 ; retCol.y = var_2 ; retCol.z = HSV.z;     }
       else if ( var_i == 4.0 ) { retCol.x = var_3 ; retCol.y = var_1 ; retCol.z = HSV.z;     }
       else                   { retCol.x = HSV.z     ; retCol.y = var_1 ; retCol.z = var_2; }
    }
    return retCol;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 uvc = -1.0*((2.0*uv) - 1.0);
    float ang = (atan(uvc.y,uvc.x)+pi)/(2.0*pi);
    ang = mod(ang - time, 1.0);
    float dist = sqrt(uvc.x*uvc.x + uvc.y*uvc.y);
    //vec3 colHSV = vec3(uv.x, 1.0, uv.y);
    //vec3 colHSV = vec3(uvc.x, 1.0, uvc.y);
    //vec3 colHSV = vec3(uvc.x, 1.0+uvc.y, abs(uvc.y));
    vec3 colHSV = vec3(ang,1.0, dist);
    vec3 colRGB = RGB_fromHSV( colHSV );
    //glFragColor = vec4(ang, dist, 0.0, 1.0);
    //glFragColor = vec4(uv,0.5+0.5*sin(time),1.0);
    glFragColor = vec4(colRGB,1.0);
}
