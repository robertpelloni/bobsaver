#version 420

// original https://www.shadertoy.com/view/4sVczt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Time simplification and easier overall speed control.

#define speed 0.9
#define scaleCo 0.25
#define rotation 1.4
#define angleOffset 0.1
#define intensity 2.1
#define outerOffset 0.9
#define polygonSides 3

#define PI 3.14159265359
#define TWOPI 6.28318530718

mat2 rot(float a){
    return mat2(
        cos(a), -sin(a),
        sin(a), cos(a)
        );
}

//from thebookofshaders.com
float polygon (vec2 st, float radius, int sides , float angle, float blur) {
    
      // Angle and radius from the current pixel
      float a = atan(st.x,st.y)+PI;
      float r = TWOPI/float(sides);

      // Shaping function that modulate the distance
      float d = cos(floor(.5+a/r)*r-a)*length(st);
      return (1.0-smoothstep(radius, radius + blur ,d));
}

void main(void)
{
    vec2 uv =  2.0*vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;    
    vec2 twistedUV =uv;
    
    vec3 bgCol = vec3(0.85,0.85,1.0);
    vec3 pixel = bgCol;
    
    float originalAngle = PI * rotation * sin(speed * time) + length(uv) * -cos(speed * (time - outerOffset)) * intensity;
    
    float i = 0.0;
    for(float j = 20.0; j > 0.0; j--)
    {    
        float scale = (j * scaleCo);
        float angle = originalAngle+  angleOffset * j;
        //twistedUV.x =   cos(angle)*uv.x + sin(angle)*uv.y;
        //twistedUV.y = - sin(angle)*uv.x + cos(angle)*uv.y;
        twistedUV *= rot(angle);
        
        if(polygon(twistedUV, 0.4 * scale, polygonSides, 0.0, 0.065) > 0.0 ||
           polygon(twistedUV, (0.4 - 0.02/scale) * scale, polygonSides, 0.0, 0.0022) > 0.0){
            i = j;
        }
    }  
    
    
        float angle = originalAngle+  angleOffset * i;
        
        float scale = (i * scaleCo);
        vec3 changingColor = 0.5 + 0.5*cos(5.0*time+  (20.0-i) * 0.9 +vec3(0,2,4));     
        
        //twistedUV.x =   cos(angle)*uv.x + sin(angle)*uv.y;
        //twistedUV.y = - sin(angle)*uv.x + cos(angle)*uv.y;
        twistedUV = uv;
           
        
        pixel = mix(pixel, (vec3(0.04 * i) + changingColor)/2.0 , polygon(twistedUV, 0.4 * scale, polygonSides, 0.0, 0.065));
        pixel = mix(pixel, (vec3(0.06 * (17.0-i)) + changingColor)/2.0 , polygon(twistedUV, (0.4 - 0.02/scale) * scale, polygonSides, 0.0, 0.0022));
    
    glFragColor =vec4(pixel, 1.0);
}

