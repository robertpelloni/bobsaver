#version 420

//Just playing around with making a flower of life in glsl
//This is my fist shader, if anyone would like to expand, tweak and improve this then go for it!!
//Would love to see more sacred geometric shaders floating around the web :)

//Dude: whoa, this is awesome! Playing around with the geometry, doing some recursion and spinning, nothing fancy yet but will keep playing with this. 
//This "sacred geometry" is remarkable though, you can find all platonic solids in there if you just add some lines ;)

//#define PETALS 

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float blur = 0.0005;
float pi = atan(1.)*4.;
float circleSize = 0.2;

struct Circle
{
    vec2 pos;
    float r;
};

vec2 cnorm(vec2 v)
{
    return v/max(abs(v.x),abs(v.y));    
}

float Process(Circle g,vec2 p)
{
    p-=g.pos;
    float an = atan(p.x,p.y);
    float ra = length(p);
    
    vec2 cs = vec2(cos(an),sin(an));
    cs = cnorm(cs);
    
    return 
        smoothstep(0.005, 0.001, distance(p, vec2(0., 0.)))*smoothstep(g.r+blur,g.r,ra)+
        smoothstep(0.02, 0.75, distance(p, vec2(0., 0.)))*smoothstep(g.r+blur,g.r,ra);
}

vec2 rotate(vec2 p, float speed)
{
    return vec2(cos(speed) * p.x + sin(speed) * p.y, -sin(speed) * p.x + cos(speed) *p.y);
}

vec3 flower(float rx, float ry, vec2 p)
{
    
    vec3 c = vec3(0.0);
    
    Circle g0 = Circle(vec2(rx,ry),circleSize);
    Circle g1 = Circle(vec2(rx,ry+0.202),circleSize);
    Circle g2 = Circle(vec2(rx,ry-0.202),circleSize);
    Circle g3 = Circle(vec2(rx-0.175,ry+0.101),circleSize);
    Circle g4 = Circle(vec2(rx+0.175,ry+0.101),circleSize);
    Circle g5 = Circle(vec2(rx-0.175,ry-0.101),circleSize);
    Circle g6 = Circle(vec2(rx+0.175,ry-0.101),circleSize);
    
    c = Process(g0,p)*vec3(0.8,0.,0.);
    c += Process(g1,p)*vec3(1.,1.,0.);
    c += Process(g2,p)*vec3(1.,0.,1.);
    c += Process(g3,p)*vec3(0.,0.,1.);
    c += Process(g4,p)*vec3(0.4,0.7,.2);
    c += Process(g5,p)*vec3(0.,1.,1.);
    c += Process(g6,p)*vec3(0.,0.42,0.45);
    
    #ifdef PETALS
    Circle g7 = Circle(vec2(rx+0.345,ry-0.202),circleSize);
    Circle g8 = Circle(vec2(rx-0.345,ry-0.202),circleSize);wd
    Circle g9 = Circle(vec2(rx+0.345,ry+0.202),circleSize);
    Circle g10= Circle(vec2(rx-0.345,ry+0.202),circleSize);
    Circle g11= Circle(vec2(rx,ry+0.404),circleSize);
    Circle g12= Circle(vec2(rx,ry-0.404),circleSize);
    Circle g13 = Circle(vec2(rx,ry),circleSize*2.);
    
    c += Process(g7,p)*vec3(0.25);
    c += Process(g8,p)*vec3(0.25);
    c += Process(g9,p)*vec3(0.25);
    c += Process(g10,p)*vec3(0.25);
    c += Process(g11,p)*vec3(0.25);
    c += Process(g12,p)*vec3(0.25);
    #endif
    
    return c;
}

void main( void ) {

    float speed = time*(1.+sin(time*.1)*.06);
    
    vec2 res = vec2(resolution.x/resolution.y,1.);
    vec2 p = ( gl_FragCoord.xy / resolution.y )-(res/2.);
    
    float radiusX  = p.x/resolution.x;
    float radiusY  = p.y/resolution.y;
    
    float a = atan(p.x,p.y)+time;
    float r = length(p);
    
    vec3 c = vec3(0.0);

    // recursion & spinage
    c+=flower(radiusX/2., radiusY/2., p);    
    c+=flower(radiusX/2., radiusY/2., rotate(p, -speed));    
    c+=flower(radiusX/2., radiusY/2., rotate(p, speed));
    speed += sin(time);
    c+=flower(radiusX/2., radiusY/2., rotate(p/1.5, -speed/2.));    
    c+=flower(radiusX/2., radiusY/2., rotate(p/1.5, speed/2.));
    
        
    glFragColor = vec4( vec3( c ), 1.0 );

}
