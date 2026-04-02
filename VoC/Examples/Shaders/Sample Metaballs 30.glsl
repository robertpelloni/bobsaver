#version 420

// original https://www.shadertoy.com/view/ssf3RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float opSmoothUnion(float d1, float d2, float k){
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdSphere(vec3 p, float s) {
    return length(p)-s;
}

float scene(vec3 p) {
    float d = 100500.;
    for (int i=0;i<16;i+=1) {
        float fi = float(i);
        vec3 dir = sin(1.2*(sin(fi)+1.)*time + fi * vec3(1.5,0.5,3.0));
        d = opSmoothUnion(
            sdSphere(p - vec3(0.,1.,3.) + 2.*dir, 0.5 + 0.2*sin(time)),
            d,
            1.3
        );    
    }
    return d;
}

vec3 marchScene(vec3 ro, vec3 rd) {
    for(float t = 0.0; t < 10.0;) {
        float h = scene(ro + rd*t);
        if( h<0.001 )
            return vec3(t, 0., 0.);
        t += h;
    }
    return vec3(-1.0);
}

vec3 calcNormal(vec3 p) {
    const float h = 1e-5; // or some other value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*scene( p + k.xyy*h ) + 
                      k.yyx*scene( p + k.yyx*h ) + 
                      k.yxy*scene( p + k.yxy*h ) + 
                      k.xxx*scene( p + k.xxx*h ) );
}

void main(void) {
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float backFreq = 4.;
    // Time varying pixel color
    float backCol = 0.5 + 0.2*pow((sin(backFreq * time) + 1.) / 2., 8.);

    // Output to screen
    glFragColor = vec4(vec3(backCol),1.0);
    
    vec3 ro = vec3(0.,0.,-1.);
    vec3 rd = vec3(uv, 0.) - ro;
    
    vec3 d = marchScene(ro, rd);
    if (d.x > -1.) {
        float colorP = pow(1.-d.x/4., 1./2.);
        glFragColor = vec4(0.9*colorP, 0.8*colorP, 0., 0.);
        
        vec3 p = ro + d.x * rd;
        vec3 n = calcNormal(p);
        float b = max(0.0, dot(n, vec3(0.577)));
        vec3 col = (0.6 + 1.3 * cos((b + time * 3.0) + vec3(0,2,4)) * vec3(0.7, 0., 0.)) * (1.3*backCol + b * 0.35);
        col *= exp( -d.x * 0.15 );
        glFragColor = vec4(col, 1.);
    }

}
