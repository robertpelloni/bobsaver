#version 420

// original https://www.shadertoy.com/view/WlBGzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = acos(-1.0), dstep = pi / 75.0, camHeight = 3.09;

const vec2 camGrid = vec2(-2.5,-2.930),
    
light1 = vec2(0.0, 0.0),
light2 = vec2(-1.57, 4.0);

const vec3 camPos = vec3(camGrid.x, camHeight, camGrid.y);

mat3 rotationMatrix(in vec3 axis, in float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

float f(in vec3 v)
{
    return (sin(distance(v.xz, light1) * 2.0 - time * 2.0) 
            + sin(distance(v.xz, light2) * 5.87 - time * 2.0))
            / 2.0;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy / resolution.y);
    st.y = st.y * 2.0 - 1.0;
    st.x = st.x - 0.5 * resolution.x / resolution.y;
    st.x *= 2.0;
    
    // direction of ray for this pixel. Rotated to point down a bit.
    vec3 rD = normalize(vec3(0.,0.0,1.0) + vec3(st, 0.0)) * rotationMatrix(vec3(1., 0., 0.), 0.714);
    float col = 0.0;
      vec3 color = vec3(col);
    
    // if rD.y is >= 0 then the ray never hits the function, so we just color the pixel black
    if (rD.y < 0.0)
    {
        // I cast the ray onto a plane with a height of 1, because the value of f() never goes above 1
        vec3 curPoint = camPos + rD * (camHeight - 1.0) / abs(rD.y);
        float curSign, dist = dstep;
        
        // curSign means whether curPoint is above or below the function
        curSign = sign(curPoint.y - f(curPoint));
        
        for (int i = 0; i < 1250; ++i)
        {
            curPoint += rD * dist;
            curSign = sign(curPoint.y - f(curPoint));
            if (curSign <= 0.0)
                break;
        }
        
        
            for (int i = 0; i < 30; ++i)
            {
               dist /= 2.0;
                curPoint += rD * dist * curSign;
                curSign = sign(curPoint.y - f(curPoint));
         }
    
            col = f(curPoint) * 0.5 + 0.5;
    }
    
    color = vec3(col);
    
      glFragColor = vec4(color, 1.0);
}
