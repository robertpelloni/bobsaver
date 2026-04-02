#version 420

// original https://www.shadertoy.com/view/Dd3fRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a + vec4(0, 33, 11, 0)))
#define path(z) 2. * vec2(sin(z * .3), cos(z * .2))
#define t time
#define r resolution

// Corre! 1: https://www.shadertoy.com/view/ddVczW

float map(vec3 p, vec3 k, float a){
        float d, dd = length(p - k) - .5;
        p.xy -= path(p.z);

        a = 1.; // bola
        while((a += a) < 17.) 
            dd += abs(
                      dot(
                          cos(p     * a * 1.), 
                          sin(p.zxy * a * 4. + t * 3.)
                      )) / a * .2;
                  
        a /= a; // tunel
        d = length(path(p.z)*.1) - length(p.xy);
        while((a += a) < 64.) 
            d += abs(
                    dot(
                        sin(p * a * 1.), 
                        vec3(8)
                    )) / a * .2;

        return min(d, dd);
}

void main(void) {
    vec2 u = gl_FragCoord.xy;
    vec4 o = vec4(0.0);
    
    o -= o;
    u = (u - r.xy / 2.) / r.y;
    
    vec3 D = vec3(u, 1);     
    
    float a, i, s, dd, d = 1., T;

    // camera
    vec3 lookAt   = vec3(0., 0., -time * 4.),
         ro       = lookAt + vec3(0., 0., -.1),
         lightPos = 
             cos(vec3(3, 4, 1) * t + vec3(0, 3.14/2., 0))
             * vec3(.5, .5, 2) + vec3(0, 0, 5) + ro;

    lookAt.xy   += path(lookAt.z);
    ro.xy       += path(ro.z);
    lightPos.xy += path(lightPos.z);

    vec3 fw = normalize(lookAt - ro),
         rt = vec3(fw.z, 0., -fw.x),
         up = cross(fw, rt),
         rd = fw + (u.x * rt + u.y * up) / 1.4;

    // raymarch
    while(i++ < 300. && d > .01)
        d = map(ro, lightPos, a),
        ro += rd * d * .08;
    
    o += (5.+ cos(t*.6)*4.) / i 
         + vec4(8, 4, 2, 0) / length(ro - lightPos) * .1 
         - 15. * d;
    
    glFragColor = o; 
}