import styles from './Hero.module.css';

export default function Hero() {
    return (
        <>
        <div className={styles.hero}>
            <img src="/images/ulry-logo.png" width={200} height={200} />
            <h1>
                Ulry
            </h1>
            <p>
                Fast and lightweight read-it-later and link archiver application for iOS
            </p>
        </div>
        </>
    )
}