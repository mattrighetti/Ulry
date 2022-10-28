import styles from './Feature.module.css';

export default function Feature({ img, title, body, odd }) {
    return (
        <>
        <div className={styles.feature}>
            { !odd ?
            <FlipInnerFeature img={img} title={title} body={body} />
            :
            <InnerFeature img={img} title={title} body={body} /> }
        </div>
        </>
    )
}

function InnerFeature({ img, title, body }) {
    return (
        <>
        <img src={img} />
        <div className={styles.text}>
            <h1>{title}</h1>
            <p>{body}</p>
        </div>
        </>
    )
}

function FlipInnerFeature({ img, title, body }) {
    return (
        <>
        <div className={styles.text}>
            <h1>{title}</h1>
            <p>{body}</p>
        </div> 
        <img src={img} />
        </>
    )
}