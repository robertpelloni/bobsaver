#version 420

//c64cosmin@gmail.com
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 pos = ( gl_FragCoord.xy / resolution.xy )-vec2(0.5,0.5);
    pos.x*=resolution.x/resolution.y;
    vec2 p=pos;
    vec2 np=p;
    np.x+=cos(p.y*20.0+time)*0.02;
    np.y+=cos(p.x*20.0+time*1.3)*0.02;
    p=np;
    float size=5.0+(cos(time*0.2)*0.5+0.5)*20.0;
    np=p;
    np.x=floor((p.y*0.5+p.x)*size)/size;
    np.y=floor((p.x*0.5-p.y)*size)/size;
    p=np;
    vec2 s=p;
    float c=length(s);
    float mult=(cos(time*0.1)*0.5+0.5)*30.0+10.0;
    vec3 color=vec3(cos(c*mult+0.1*time),
                cos(c*mult+0.1*time*3.0),
                cos(c*mult+0.1*time*5.0));
    glFragColor = vec4( vec3( color ), 1.0 );

}
