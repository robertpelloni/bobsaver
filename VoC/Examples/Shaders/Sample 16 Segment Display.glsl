#version 420

// original https://www.shadertoy.com/view/XlSGWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by randy read - rcread/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//    sdSegment from iq -- https://www.shadertoy.com/view/Xlf3zl 
float sdSegment( in vec2 p, in vec2 a, in vec2 b ) {
    vec2 pa = p - a, ba = b - a;
    return length( pa - ba * clamp( dot( pa, ba ) / dot( ba, ba ), 0.0, 1.0 ) );
}

float segment_dist( vec2 p, vec4 s ) {
    return sdSegment( p, s.xy, s.zw );
}

float abc[26];

void init_abc() {
    abc[0]    = .949951171875;        abc[1]    = .863037109375;        abc[2]    = .80859375;            abc[3]    = .800537109375;
    abc[4]    = .93359375;            abc[5]    = .88671875;            abc[6]    = .871337890625;        abc[7]    = .199951171875;
    abc[8]    = .7998046875;            abc[9]    = .051513671875;        abc[10] = .1367950439453125;    abc[11] = .05859375;
    abc[12] = .01263427734375;        abc[13] = .0125885009765625;    abc[14] = .809326171875;        abc[15] = .94970703125;
    abc[16] = .8093414306640625;    abc[17] = .9497222900390625;    abc[18] = .992431640625;        abc[19] = .7529296875;
    abc[20] = .059326171875;        abc[21] = .011810302734375;        abc[22] = .0124969482421875;    abc[23] = .0002288818359375;
    abc[24] = .19677734375;            abc[25] = .796966552734375;
}

float get_abc( float i ) {
    return    i < 16. ?    ( i < 8. ?    ( i < 4. ?    ( i < 2. ?    ( i <  1. ? abc[ 0] : abc[ 1] ) :
                                                            ( i <  3. ? abc[ 2] : abc[ 3] ) ) :
                                                ( i < 6. ?    ( i <  5. ? abc[ 4] : abc[ 5] ) :
                                                            ( i <  7. ? abc[ 6] : abc[ 7] ) ) ) :
                                    ( i < 12. ?    ( i < 10. ?    ( i <  9. ? abc[ 8] : abc[ 9] ) :
                                                            ( i < 11. ? abc[10] : abc[11] ) ) :
                                                ( i < 14. ?    ( i < 13. ? abc[12] : abc[13] ) :
                                                            ( i < 15. ? abc[14] : abc[15] ) ) ) ) :
                        ( i < 24. ?    ( i < 20. ?    ( i < 18. ?    ( i < 17. ? abc[16] : abc[17] ) :
                                                            ( i < 19. ? abc[18] : abc[19] ) ) :
                                                ( i < 22. ?    ( i < 21. ? abc[20] : abc[21] ) :
                                                            ( i < 23. ? abc[22] : abc[23] ) ) ) :
                                                            ( i < 25. ? abc[24] : abc[25] ) );
}

vec4 sgmt[16];
vec2 sk = vec2( 2. );    //    vec2( 2.5, 2.25 ) for stone age

void init_segments( vec4 r ) {
    vec2 a=r.xy, c=r.zy, b=(a+c)/2., g=r.xw, d=(a+g)/sk.x, i=r.zw, e=(a+i)/sk.y, f=(c+i)/2., h=(g+i)/2.;
    sgmt[ 0]=vec4(a,b); sgmt[ 1]=vec4(b,c); sgmt[ 2]=vec4(d,e); sgmt[ 3]=vec4(e,f);
    sgmt[ 4]=vec4(g,h); sgmt[ 5]=vec4(h,i); sgmt[ 6]=vec4(a,d); sgmt[ 7]=vec4(d,g);
    sgmt[ 8]=vec4(b,e); sgmt[ 9]=vec4(e,h); sgmt[10]=vec4(c,f); sgmt[11]=vec4(f,i);
    sgmt[12]=vec4(a,e); sgmt[13]=vec4(c,e); sgmt[14]=vec4(e,g); sgmt[15]=vec4(e,i);
}

void init_segments( vec2 r ) {
    init_segments( vec4( 0., r.y, r.x, 0. ) );
}

vec3 segment_display( vec2 p, float a, float line_width, vec3 color ) {
    float d = resolution.x, s = .5, pixel_size = 1., c = mod( time * 3. / 26., 3. );
    for ( int i = 0 ; i < 16 ; i++ ) {
        if ( a >= s ) {
            d = min( d, segment_dist( p, sgmt[i] ) );
            a -= s;
        }
        s *= .5;
    }
    if ( c <= 1. ) {
        return mix( vec3( 0. ), color, 1. - ( d - line_width ) * 2. / ( line_width * pixel_size  ) );
    } else if ( c <= 2. ) {
        return mix( vec3( 0. ), color, 1. - ( d - line_width ) * 2. / ( line_width * pixel_size  ) )
            + color * 1e3 / ( d * d );
    } else {
        return color * 2e1 * line_width * line_width / ( d * d );
    }
}

vec3 my_main( vec2 p ) {
    vec2 gr = vec2( 2., 1. + sqrt( 5. ) );    //    golden ratio
    float m = .1 * resolution.y;

    init_abc();
    init_segments( floor( m * gr ) );
    return segment_display( floor( p + m - resolution.xy / 2. ), 
                            get_abc( mod( time * 3., 26. ) ), 
                            floor( m  / 1e1 ),
                              vec3( 1., fract( p / 3. ) * vec2( .35, .55 ) ) );
}

void main(void)
{
    glFragColor.rgb = my_main( floor( gl_FragCoord.xy ) );
}
