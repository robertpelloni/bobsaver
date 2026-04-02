#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 5
#define M 8
#define PI 3.1415926535
void main( void ) {

    vec2 v = (gl_FragCoord.xy - resolution/2.0) / min(resolution.y,resolution.x) * 200.0;
    
    float col = 0.0;
    
    for ( int j = 0; j < M; j ++ ){
        float jt = fract((float(j) - time)/float(M));
        float m = pow((1.7+mouse.x*.4),(jt-.5)*float(M));
        float a = sin(jt*PI);
                
        for ( int i = 0; i < N; i++ ){
            float th = 2.0*PI*float(i)/float(N);
            float c = cos(th);
            float s = sin(th);
            
            col += sin((v.x*s + v.y*c)*m + time*0.357 )*a/m;
        }
    }
    col = log(abs(col)+1.0)*0.3;
    glFragColor = vec4( cos(col), cos(col*2.0), cos(col*4.0), 1.0 );

}
