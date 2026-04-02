#version 420

// original https://www.shadertoy.com/view/llyfWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rando( vec2 p ) {
    vec3 q = vec3( dot(p,vec2(127.1,311.7)),
                   dot(p,vec2(269.5,183.3)),
                   dot(p,vec2(419.2,371.9)) );
    return fract(sin(q)*43758.5453);
}
vec3 random3(vec2 c) {
    float j = 4096.0*sin(dot(vec3(c,(c.x*c.y)),vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}
float celularnoise( in vec2 x) {
    //Numero y su fracion
    vec2 p = floor(x);
    vec2 f = fract(x);
    
    float k = 50.;// on este valor funciona bien
    vec3 o=vec3(0.);
    float va = 0.0;
    float wt = 0.0;
    for (int j=-1; j<=1; j++) {
        for (int i=-1; i<=1; i++) {
            //Celula vecinas
            vec2 g = vec2(float(i),float(j));
            //Random(ruido)
            vec3 o = random3(p + g);
            //Animate Cells(cambia forma y color durante el tiempo)
            o = 0.5+0.5*sin(time+10.*o);
            //celula vecina menos el la fraccion del vector visto, mas un numero "random"(f(n)=sin)
            vec2 r = g - f + o.xy;
            //distancia entre celulas
            float d = dot(r,r);
            //tamaño desde el centro, busque y con smothstep funcionaba
            float ww = pow( 1.0-smoothstep(0.0,sqrt(2.),sqrt(d)), k );
            //ww por el numero "random"(f(n)=sin)
            //fraccion para la suma del centro de cada celula ponderada por el random o.z iterada
            va += o.z*ww;
            wt += ww;
        }
    }

    return va/wt;
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st.x *= resolution.x/resolution.y;
    vec3 color = vec3(0.0);
    //Scale
    float s=5.;
    //Translate point;
    st.x+=sin(time*0.3)*3.;
    //estos eran de prueba
    //st.y+=(1.+cos(time))/s;
    //st.x+=time/s;
    //Scale st.
    st *= s;
    //aplica celularnoise
    float n = celularnoise(st);
    //printea
    glFragColor = vec4(vec3(n),1.0);
}
