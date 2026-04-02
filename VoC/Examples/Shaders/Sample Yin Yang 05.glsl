#version 420

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

vec2 rotate(vec2 p, float a){
    return vec2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a)); //R*P
}
float cercle(vec2 p){ //TODO : smooth
    float d = length(p);
    float c = 1.-step(1.,d);
    return clamp(c,0.,1.);
}
float cerclesmooth(vec2 p, float s){
    float d = length(p);
    float c = cercle(p);
    c+=abs(0.001*s/(d-1.));
    return clamp(c,0.,1.);
    //return c;
}
float demicercle(vec2 p,float sign){
    if(sign*p.x >0.) return 0.;
    return cercle(p);
}
float YY(vec2 p, float s){
    float d = length(p);
    float c=0.;
    c+=demicercle(p,1.);
    c+=cerclesmooth(2.*(p+vec2(0.,0.5)),4.*s); //bras blanc
    c=clamp(c,0.,1.);
    c-=cerclesmooth(2.*(p+vec2(0.,-0.5)),4.*s); //bras noir
    c=clamp(c,0.,1.);
    c+=cerclesmooth(8.*(p+vec2(0.,-0.5)),10.*s); //petit rond blanc
    c-=cerclesmooth(8.*(p+vec2(0.,0.5)),10.*s);
    c=clamp(c,0.,1.);
    c+=abs(0.004*s/(d-1.)); //halo externe
    c=clamp(c,0.,1.);
    return c;
}
#define fact 12.
float fYY(in vec2 p){
    float smoot = 0.5; //0.5 to 8
    p*= pow(fact,fract(1.42*time));
    p/=fact*fact;
    float c = YY(p,smoot);
    float ct;
    for(int i=0;i<4;i++){
        //p=fact*rotate(p,PI_OVER_2);
        p*=fact;
        smoot *=2.;
        ct=YY(p,smoot);
        if(length(p)<1.) c=ct; else c+=ct;
    }
    c=clamp(c,0.,1.);
    return c;
}
void main(){
    vec2 p = (2.*gl_FragCoord.xy-resolution)/min(resolution.x,resolution.y);
    p = rotate(p,0.42*time);
    float c = fYY(p);
    glFragColor = vec4(vec3(c),1.);

}
/*

sheldonCM - 2014
better viewed in 1:1
controlled by a Wii nunchuck on Arduino board over Processing
not really mathematically elegant or optimized (dem IF statements...)
no religious purpose here
only wanted to do this for a long time, and now able to do it
thx to iq, mr.doob and many others, every little wizard sharing code and knowledge

*/
