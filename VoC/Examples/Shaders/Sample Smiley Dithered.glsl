#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 NCoord = vec2(gl_FragCoord) - resolution/2.0 - 0.5;

    //if (NCoord.x == 0.0 || NCoord.y == 0.0)        glFragColor = vec4( 1.0, 1.0, 1.0, 1.0 );
    
    float x = NCoord.x;
    float y = NCoord.y;
    
    float epsilon = 20.0;
    
    float t = 1.0*time;
    
    float fr = 10000.0;
    float er = 1000.0;
    float mr = 8000.0;
    float nr = 100.0;
    
    float vdx = 2.0 * -(90.0 - sqrt(er)) * sin(t);
    float vdy = 1.0 * -(90.0 - sqrt(er)) * cos(t);

    vec2 c = vec2(vdx, vdy);
    
    vec2 cel = vec2(vdx - 90.0, vdy + 50.0);
    vec2 cer = vec2(vdx + 90.0, vdy + 50.0);
    vec2 cm = vec2(vdx, vdy);
    vec2 cn = vec2(vdx, vdy);
    
    float pattern = 7.0 * (abs(cos(x)*sin(y)));
    
    #define FACEBORDER    (abs(pow(x - c.x - sin(y/10.0)*10.0, 2.0)/6.0 + pow(y - c.y - sin(x/10.0)*10.0,2.0)/2.0 - fr) < 20.0 * pattern)
    #define EYEBROWS_L    (abs(pow(x-cel.x, 2.0)/1.0 + pow(y-cel.y, 2.0)/1.0 - er) < 15.0 * pattern && y > (cel.y + 20.0))
    #define EYEBROWS_R    (abs(pow(x-cer.x, 2.0)/1.0 + pow(y-cer.y, 2.0)/1.0 - er) < 15.0 * pattern && y > (cer.y + 20.0))
    #define EYEBROWS    (EYEBROWS_L || EYEBROWS_R)
    #define EYES_L        (abs(pow(x-cel.x, 2.0)/1.0 + pow(y-cel.y,2.0)/2.0 - nr) < 15.0 * pattern)
    #define EYES_R        (abs(pow(x-cer.x, 2.0)/1.0 + pow(y-cer.y,2.0)/2.0 - nr) < 15.0 * pattern)
    #define EYES        (EYES_L || EYES_R)
    #define MOUTH        (abs(pow(x-cm.x, 2.0)/2.0 + pow(y-cm.y, 2.0)/1.0 - mr) <80.0 * pattern && y < cm.y)
    #define NOSE        (abs(pow(x-cn.x, 2.0)/1.0 + pow(y-cn.y,2.0)/1.0 - nr) < 20.0 * pattern)
    
    
    #define FACE        (FACEBORDER || EYEBROWS || EYES || NOSE || MOUTH)
    
    if (FACE)
        //glFragColor = vec4( sin(time), sin(time + 3.14/2.0), sin(time+3.24*4.0/3.0), 1.0 );
        glFragColor = vec4(1.0, sin(time), 0.75*cos(time), 1.0);
    
    //if (abs(sin(x/40. + time)-y/40.) < 0.2*sin(x*y))
    //    glFragColor = vec4(1.0);
}
