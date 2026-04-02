#version 420

// original https://www.shadertoy.com/view/wtfGWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float line( in vec2 p, in vec2 a, in vec2 b, float th ){
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return smoothstep(th, th + 0.0005,length( pa - ba*h ));
}

float axis(vec2 uv){
    float h = 1.0;
     vec2 v = smoothstep(0.004, 0.0041, abs(uv));
    
    float inc = 1.0 / 5.0;
    
    for(float i = -2.0; i < 2.0; i += inc){
         h *= line(uv, vec2(i, 0.03), vec2(i, -0.03), 0.004);   
    }
    for(float i = -2.0; i < 2.0; i += inc){
         h *= line(uv, vec2(0.03, i), vec2(-0.03, i), 0.004);   
    }
    
    return v.x * v.y * h;
    
}

float Mandelbrot(vec2 c)
{
    vec2 z = vec2(0.0);
    for (int i = 0; i < 64; i++)
    {
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        if( dot(z,z) > 128.0) return float(i) - log2(log2(dot(z,z)));
    }
    return 0.0;
}

int Julia(vec2 uv, vec2 m) {
    vec2 z = uv;
    for (int i = 0; i < 100; i++) 
    {
        if (dot(z,z) > 2.) return i;
        z = mat2(z,-z.y,z.x) * z + m;
    }
    return 0;
}

// comment out for julia set
#define mandelbrodt

void main(void) //WARNING - variables void ( out vec4 f, in vec2 u ) need changing to glFragColor and gl_FragCoord
{
    vec2 u = gl_FragCoord.xy;
    vec2 R = resolution.xy;
    vec2 uv = 2.0*vec2(u.xy - 0.5*R.xy)/R.y;
    vec2 m = 2.0*(mouse*resolution.xy.xy / R.xy-.5); 
    m.x *= R.x/R.y;
    
    vec3 col = vec3(axis(uv));

    
    
    col = mix(vec3(0.0, 1.0, 0.0), col, 
              smoothstep(0.029, 0.0295, length(uv - m.xy)));
    
    vec2 p1 = vec2(0);
    vec2 p2 = m.xy;
    
    #ifdef mandelbrodt
    float mand = float(Mandelbrot(uv));
    col = mix(col, vec3(1.0, 0.0, 0.0), mand / 20.);
    for(float i = 0.0; i < 70.0; i++)
    {
        vec2 np = vec2((p1.x * p1.x - p1.y * p1.y), 
                         (2.0 * p1.x * p1.y)) + m.xy;
        
        np = clamp(np, -4.0, 4.0);
        col *= line(uv, p1, np, 0.005);
        col = mix(vec3(0.0, 0.0, 1.0), col, smoothstep(0.024, 0.0245, length(uv - np)));
        p1 = np;
    }
      #else
    // Also shows the diverging when the bounds is just the circle
    for(float i = 0.0; i < 100.0; i++)
    {
        vec2 np = vec2((p2.x * p2.x - p2.y * p2.y), 
                         (2.0 * p2.x * p2.y));
         
        np = clamp(np, -4.0, 4.0);
        col *= line(uv, p2, np, 0.005);
        col = mix(vec3(0.0, 0.0, 1.0), col, smoothstep(0.029, 0.0295, length(uv - np)));
        p2 = np;
        
    }
    float circ = smoothstep(1.0, 1.01, length(uv)) + 
        smoothstep(0.999, 0.991, length(uv));
    col *= circ;
    float jule = float(Julia(-uv, m));
    col = mix(col, vec3(1.0, 0.0, 0.0), jule / 20.);
    #endif
    
    glFragColor = vec4(col, 1.0);
}

