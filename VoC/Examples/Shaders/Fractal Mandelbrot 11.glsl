#version 420

// original https://www.shadertoy.com/view/wstBWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 2

float mandelbrot( in vec2 c ) {
    const float B = 32.0;
    float l = 0.0;
    vec2 z  = vec2(0.0);
    for( int i=0; i<128; i++ ) {
        z = vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c;
        if( dot(z,z)>(B*B) ) break;
        l += 1.0;
    }
    if(l>127.0) return z.x*z.y*16000.0;
    return l;
}

void main(void) {
    vec3 col = vec3(0.0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ ) {
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+vec2(float(m),float(n))/float(AA)))/resolution.y;
        float w = float(AA*m+n);
        float time = time + 0.5*(1.0/24.0)*w/float(AA*AA);
        float zoom = 0.8 + 0.2*cos(0.1*time);
        float coa = cos( 0.15*(1.0-zoom)*time );
        float sia = sin( 0.15*(1.0-zoom)*time );
        zoom = pow(zoom,20.0);
        vec2 xy = vec2( p.x*coa-p.y*sia, p.x*sia+p.y*coa );
        vec2 c = vec2(-1.37,.02) + xy*zoom;
        float l = mandelbrot(c);
        col += 0.5 + 0.5*cos( 3.0 + l*0.1 + vec3(0.0,0.6,1.0));
    }
    col /= float(AA*AA);
    glFragColor = vec4( col, 1.0 );
}
