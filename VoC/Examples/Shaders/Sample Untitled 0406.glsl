#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 uv =  (gl_FragCoord.xy -.5 * resolution.xy) / resolution.y ;
    
    float t = time * .8;
    
    vec3 ro = vec3(0, 0, -1);
        vec3 lookat = vec3(sin(t)/2.0 - 1.0, cos(t)/2.0 - 2.0, 0.0);
        float zoom = 0.05 + sin(t) / 50.0;
    
        vec3 f = normalize(lookat - ro),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f, r),
        c = ro + f * zoom,
        i = c + uv.x * r + uv.y * u,
        rd = normalize(i-ro);
    
        float dS, dO;
        vec3 p;
    
        for(int i=0; i<1000; i++) {
            p = ro + rd * dO;
            dS = -(length(vec2(length(p.yz)-1.0, p.x)) - 0.65 - (cos(t) + sin(t)) / 10.0);
            if(dS<.0001) break;
            dO += dS;
       }
    
      vec3 col = vec3(0);
    
    float x = atan(p.y, p.z) + t * 0.5;
    float y = atan(length(p.yz)-1., p.x);
    
    // Basically vert / horiz
    float bands = sin(y*20.+x*20.);
    
    // Size and orientation.
    float ripples = sin((x*20.-y*40.)*3.)*.5+.5;
    
    // Speed & size
    float waves = sin(x*30.+y*10.+t*6.);
    
    float b1 = smoothstep(-0.0, 1.0, bands-0.5);
    float b2 = smoothstep(-0.5, .5, bands-.35);
    
    float m = b1*(1.4-b2);
    m = max(m, ripples*b2*max(0., waves));
    m += max(0., waves*.65*b2);
    
    float fd = length(ro-p);
    col += m;
    col.rb *= 2.5;
    col.z *= 2.5*abs(cos(t));
    col = mix(col, vec3(0.2,0.75,0.75), 1.-exp(-0.80*fd*fd));

    glFragColor = vec4( col, 1.0 );
}
